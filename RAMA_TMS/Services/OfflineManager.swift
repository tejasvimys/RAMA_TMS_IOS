//
// OfflineManager.swift
// RAMA_TMS
//
// Created by Tejasvi Mahesh on 1/2/26.
// Consolidated Offline Sync & Network Manager
//

import Foundation
import CoreData
import Combine
import Network

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}

class OfflineManager: ObservableObject {
    static let shared = OfflineManager()
    
    // MARK: - Published Properties
    
    @Published var isOnline = true
    @Published var isSyncing = false
    @Published var pendingSyncCount = 0
    @Published var pendingEmailCount = 0
    @Published var lastSyncTime: Date?
    @Published var syncProgress: Double = 0.0
    @Published var currentSyncItem: String?
    
    // MARK: - Private Properties
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.ramatms.offlinemonitor")
    private var syncTimer: Timer?
    private let context = PersistenceController.shared.container.viewContext
    
    // MARK: - Initialization
    
    private init() {
        startNetworkMonitoring()
        updatePendingCounts()
        startAutoSync()
    }
    
    deinit {
        monitor.cancel()
        syncTimer?.invalidate()
    }
    
    // MARK: - Network Monitoring
    
    func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                let wasOffline = !self.isOnline
                let newStatus = path.status == .satisfied
                
                // Only update if status actually changed
                if self.isOnline != newStatus {
                    self.isOnline = newStatus
                    
                    print(newStatus ? "📶 Network: ONLINE" : "📵 Network: OFFLINE")
                    
                    // 🔥 POST NOTIFICATION
                    NotificationCenter.default.post(
                        name: .networkStatusChanged,
                        object: newStatus
                    )
                    
                    // If we just came back online, trigger sync
                    if wasOffline && newStatus {
                        print("🔄 Network restored - triggering auto-sync")
                        self.syncAllPendingData()
                    }
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    // MARK: - Auto Sync Timer
    
    private func startAutoSync() {
        // Sync every 5 minutes when online
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.isOnline && (self.pendingSyncCount > 0 || self.pendingEmailCount > 0) {
                self.syncAllPendingData()
            }
        }
    }
    
    // MARK: - Save Donation Offline
    
    func saveDonationOffline(
        donorName: String,
        donorEmail: String?,
        donorPhone: String?,
        amount: Decimal,
        donationType: String,
        paymentMethod: String,
        notes: String?,
        collectorEmail: String,
        shouldSendEmail: Bool = false
    ) -> OfflineDonation {
        let donation = OfflineDonation(context: context)
        donation.id = UUID()
        donation.donorName = donorName
        donation.donorEmail = donorEmail
        donation.donorPhone = donorPhone
        donation.amount = NSDecimalNumber(decimal: amount)
        donation.donationType = donationType
        donation.paymentMethod = paymentMethod
        donation.notes = notes
        donation.receiptNumber = generateReceiptNumber()
        donation.createdAt = Date()
        donation.collectorEmail = collectorEmail
        donation.syncStatus = "pending"
        donation.syncAttempts = 0
        
        PersistenceController.shared.save()
        updatePendingCounts()
        
        print("✅ Donation saved offline: \(donation.receiptNumber)")
        
        // Try to sync immediately if online
        if isOnline {
            syncAllPendingData()
        }
        
        return donation
    }
    // MARK: - Sync All Pending Data
    
    func syncAllPendingData() {
        guard !isSyncing && isOnline else { return }
        
        isSyncing = true
        currentSyncItem = "Starting sync..."
        syncProgress = 0.0
        
        print("🔄 Starting sync process...")
        
        Task {
            await syncDonations()
            
            await MainActor.run {
                isSyncing = false
                lastSyncTime = Date()
                currentSyncItem = nil
                syncProgress = 1.0
                updatePendingCounts()
                print("✅ Sync completed")
            }
        }
    }
    
    // MARK: - Sync Donations
    
    private func syncDonations() async {
        let fetchRequest: NSFetchRequest<OfflineDonation> = OfflineDonation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "syncStatus == %@ OR syncStatus == %@", "pending", "failed")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        
        guard let pendingDonations = try? context.fetch(fetchRequest) else { return }
        
        let totalCount = pendingDonations.count
        guard totalCount > 0 else { return }
        
        print("📤 Syncing \(totalCount) donation(s)...")
        
        for (index, donation) in pendingDonations.enumerated() {
            await MainActor.run {
                currentSyncItem = "Syncing donation \(index + 1) of \(totalCount)"
                syncProgress = Double(index) / Double(totalCount)
            }
            
            await syncDonation(donation)
        }
    }
    
    private func syncDonation(_ donation: OfflineDonation) async {
        await MainActor.run {
            donation.syncStatus = "syncing"
            donation.syncAttempts += 1
            donation.lastSyncAttempt = Date()
            PersistenceController.shared.save()
        }
        
        do {
            // Convert offline donation to API request format
            let request = convertToOnlineRequest(donation)
            
            // ✅ REAL API CALL - Backend will send email automatically
            let data = try await QuickDonationApi.shared.submitQuickDonation(request)
            
            // Parse response to get server IDs
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let response = try decoder.decode(QuickDonationResponse.self, from: data)
            
            await MainActor.run {
                donation.syncStatus = "synced"
                donation.serverDonationId = response.donorReceiptDetailId
                donation.errorMessage = nil
                PersistenceController.shared.save()
                print("✅ Synced: \(donation.receiptNumber) → Server ID: \(response.donorReceiptDetailId)")
                print("📧 Backend automatically sent email receipt")
            }
            
        } catch {
            await MainActor.run {
                donation.syncStatus = "failed"
                donation.errorMessage = error.localizedDescription
                
                if donation.syncAttempts >= 3 {
                    donation.syncStatus = "failed_permanent"
                    print("❌ Permanent failure: \(donation.receiptNumber)")
                }
                
                PersistenceController.shared.save()
            }
        }
    }
    
    // MARK: - Convert Offline Donation to API Request
    
    private func convertToOnlineRequest(_ offline: OfflineDonation) -> QuickDonorAndDonationRequest {
        // Split name into first/last (basic split)
        let nameParts = offline.donorName.components(separatedBy: " ")
        let firstName = nameParts.first ?? offline.donorName
        let lastName = nameParts.dropFirst().joined(separator: " ")
        
        let donor = QuickDonorDto(
            firstName: firstName,
            lastName: lastName.isEmpty ? firstName : lastName,
            phone: offline.donorPhone,
            email: offline.donorEmail,
            address1: nil,
            address2: nil,
            city: nil,
            state: nil,
            country: nil,
            postalCode: nil,
            isOrganization: false,
            organizationName: nil,
            donorType: "Individual"
        )
        
        let donation = QuickDonationDto(
            donationAmt: offline.amount.doubleValue,
            donationType: offline.donationType,
            dateOfDonation: offline.createdAt,
            paymentMode: offline.paymentMethod,
            referenceNo: offline.receiptNumber,
            notes: offline.notes
        )
        
        return QuickDonorAndDonationRequest(donor: donor, donation: donation)
    }
    
    // MARK: - Manual Retry Methods
    
    func retryFailedDonation(_ donation: OfflineDonation) {
        donation.syncStatus = "pending"
        donation.errorMessage = nil
        PersistenceController.shared.save()
        updatePendingCounts()
        
        if isOnline {
            syncAllPendingData()
        }
        
        print("🔄 Retrying donation: \(donation.receiptNumber)")
    }
    // MARK: - Fetch Methods
    
    func getAllDonations() -> [OfflineDonation] {
        let fetchRequest: NSFetchRequest<OfflineDonation> = OfflineDonation.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        return (try? context.fetch(fetchRequest)) ?? []
    }
    
    func getPendingDonations() -> [OfflineDonation] {
        let fetchRequest: NSFetchRequest<OfflineDonation> = OfflineDonation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "syncStatus != %@", "synced")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        return (try? context.fetch(fetchRequest)) ?? []
    }
    
    func getSyncedDonations() -> [OfflineDonation] {
        let fetchRequest: NSFetchRequest<OfflineDonation> = OfflineDonation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "syncStatus == %@", "synced")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        return (try? context.fetch(fetchRequest)) ?? []
    }
    
    func getFailedDonations() -> [OfflineDonation] {
        let fetchRequest: NSFetchRequest<OfflineDonation> = OfflineDonation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "syncStatus == %@ OR syncStatus == %@", "failed", "failed_permanent")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        return (try? context.fetch(fetchRequest)) ?? []
    }
    
    func getDonation(byReceiptNumber receiptNumber: String) -> OfflineDonation? {
        let fetchRequest: NSFetchRequest<OfflineDonation> = OfflineDonation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "receiptNumber == %@", receiptNumber)
        fetchRequest.fetchLimit = 1
        
        return try? context.fetch(fetchRequest).first
    }
    
    // MARK: - Delete Methods
    
    func deleteDonation(_ donation: OfflineDonation) {
        print("🗑️ Deleting donation: \(donation.receiptNumber)")
        context.delete(donation)
        PersistenceController.shared.save()
        updatePendingCounts()
    }
    
    func deleteAllSyncedDonations() {
        let donations = getSyncedDonations()
        donations.forEach { context.delete($0) }
        PersistenceController.shared.save()
        updatePendingCounts()
        print("🗑️ Deleted \(donations.count) synced donation(s)")
    }
    
    // MARK: - Statistics
    
    func getStatistics() -> (total: Int, synced: Int, pending: Int, failed: Int) {
        let all = getAllDonations()
        let synced = all.filter { $0.syncStatus == "synced" }.count
        let pending = all.filter { $0.syncStatus == "pending" }.count
        let failed = all.filter { $0.syncStatus == "failed" || $0.syncStatus == "failed_permanent" }.count
        
        return (all.count, synced, pending, failed)
    }
    
    func getTotalOfflineAmount() -> Decimal {
        let donations = getAllDonations()
        return donations.reduce(Decimal(0)) { $0 + ($1.amount as Decimal) }
    }
    
    func getPendingAmount() -> Decimal {
        let donations = getPendingDonations()
        return donations.reduce(Decimal(0)) { $0 + ($1.amount as Decimal) }
    }
    
    // MARK: - Helper Methods
    
    func updatePendingCounts() {
        let donationFetchRequest: NSFetchRequest<OfflineDonation> = OfflineDonation.fetchRequest()
        donationFetchRequest.predicate = NSPredicate(format: "syncStatus == %@ OR syncStatus == %@", "pending", "failed")
        pendingSyncCount = (try? context.count(for: donationFetchRequest)) ?? 0
    }
    
    private func generateReceiptNumber() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let random = Int.random(in: 1000...9999)
        return "OFF-\(timestamp)-\(random)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func formatAmount(_ amount: NSDecimalNumber) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount) ?? "$0.00"
    }
    
    // MARK: - Force Sync (Manual)
    
    func forceSyncNow() {
        if isOnline {
            syncAllPendingData()
        } else {
            print("⚠️ Cannot force sync - device is offline")
        }
    }
    
    // MARK: - Clear Old Synced Data
    
    func clearOldSyncedData(olderThanDays days: Int = 30) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let fetchRequest: NSFetchRequest<OfflineDonation> = OfflineDonation.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "syncStatus == %@ AND createdAt < %@",
            "synced",
            cutoffDate as NSDate
        )
        
        guard let oldDonations = try? context.fetch(fetchRequest) else { return }
        
        oldDonations.forEach { context.delete($0) }
        PersistenceController.shared.save()
        
        print("🗑️ Cleared \(oldDonations.count) old synced donation(s)")
    }
}

// MARK: - Extensions for Status Display

extension OfflineDonation {
    var syncStatusDisplay: String {
        switch syncStatus {
        case "pending": return "Pending Sync"
        case "syncing": return "Syncing..."
        case "synced": return "Synced"
        case "failed": return "Failed"
        case "failed_permanent": return "Failed (Permanent)"
        default: return syncStatus
        }
    }
    
    var syncStatusColor: String {
        switch syncStatus {
        case "synced": return "green"
        case "pending": return "orange"
        case "syncing": return "blue"
        case "failed", "failed_permanent": return "red"
        default: return "gray"
        }
    }
    
    var formattedAmount: String {
        OfflineManager.shared.formatAmount(amount)
    }
}

