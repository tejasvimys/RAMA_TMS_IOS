//
// OfflineManager.swift
// RAMA_TMS
//
// Created by Tejasvi Mahesh on 1/2/26.
// Consolidated Offline Sync & Network Manager
// Updated: 1/3/26 - Complete field mapping and bug fixes
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
                    
                    // POST NOTIFICATION
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
    
    // MARK: - Save Donation Offline (UPDATED with all fields)
    
    func saveDonationOffline(
        donorName: String,
        donorEmail: String?,
        donorPhone: String?,
        amount: Decimal,
        donationType: String,
        paymentMethod: String,
        paymentReference: String? = nil,
        notes: String?,
        collectorEmail: String,
        // Address fields
        address1: String? = nil,
        address2: String? = nil,
        city: String? = nil,
        state: String? = nil,
        country: String? = nil,
        postalCode: String? = nil,
        // Organization fields
        isOrganization: Bool = false,
        organizationName: String? = nil,
        shouldSendEmail: Bool = false
    ) -> OfflineDonation {
        let donation = OfflineDonation(context: context)
        donation.id = UUID()
        
        // Donor info
        donation.donorName = donorName
        donation.donorEmail = donorEmail
        donation.donorPhone = donorPhone
        
        // Address info
        donation.address1 = address1
        donation.address2 = address2
        donation.city = city
        donation.state = state
        donation.country = country
        donation.postalCode = postalCode
        
        // Organization info
        donation.isOrganization = isOrganization
        donation.organizationName = organizationName
        donation.donorType = isOrganization ? "Organization" : "Individual"
        
        // Donation info
        donation.amount = NSDecimalNumber(decimal: amount)
        donation.donationType = donationType
        donation.paymentMethod = paymentMethod
        donation.paymentReference = paymentReference
        donation.notes = notes
        donation.receiptNumber = generateReceiptNumber()
        donation.createdAt = Date()
        donation.collectorEmail = collectorEmail
        donation.syncStatus = "pending"
        donation.syncAttempts = 0
        
        PersistenceController.shared.save()
        updatePendingCounts()
        
        print("✅ Donation saved offline: \(donation.receiptNumber)")
        print("   Donor: \(donorName)")
        print("   Amount: $\(amount)")
        print("   Type: \(donationType)")
        print("   Organization: \(isOrganization)")
        
        // Try to sync immediately if online
        if isOnline {
            print("🔄 Device is online - triggering immediate sync")
            syncAllPendingData()
        } else {
            print("📴 Device is offline - will sync when connection restored")
        }
        
        return donation
    }
    
    // MARK: - Sync All Pending Data
    
    func syncAllPendingData() {
        guard !isSyncing && isOnline else {
            if !isOnline {
                print("⚠️ Cannot sync - device is offline")
            }
            return
        }
        
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
                print("✅ Sync completed at \(formatDate(Date()))")
            }
        }
    }
    
    // MARK: - Sync Donations
    
    private func syncDonations() async {
        let fetchRequest: NSFetchRequest<OfflineDonation> = OfflineDonation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "syncStatus == %@ OR syncStatus == %@", "pending", "failed")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        
        guard let pendingDonations = try? context.fetch(fetchRequest) else {
            print("⚠️ No pending donations to sync")
            return
        }
        
        let totalCount = pendingDonations.count
        guard totalCount > 0 else {
            print("✅ No donations to sync")
            return
        }
        
        print("📤 Syncing \(totalCount) donation(s)...")
        
        for (index, donation) in pendingDonations.enumerated() {
            await MainActor.run {
                currentSyncItem = "Syncing donation \(index + 1) of \(totalCount)"
                syncProgress = Double(index) / Double(totalCount)
            }
            
            await syncDonation(donation)
            
            // Small delay between syncs to avoid overwhelming the server
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
    }
    
    private func syncDonation(_ donation: OfflineDonation) async {
        await MainActor.run {
            donation.syncStatus = "syncing"
            donation.syncAttempts += 1
            donation.lastSyncAttempt = Date()
            PersistenceController.shared.save()
        }
        
        print("⬆️ Syncing: \(donation.receiptNumber) (Attempt \(donation.syncAttempts))")
        
        do {
            // Convert offline donation to API request format
            let request = convertToOnlineRequest(donation)
            
            // REAL API CALL - Backend will send email automatically
            let data = try await QuickDonationApi.shared.submitQuickDonation(request)
            
            // Enhanced response logging
            print("📦 Response size: \(data.count) bytes")
            
            if data.isEmpty {
                print("⚠️ Response is empty")
            } else if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON response: \(jsonString)")
            } else {
                print("⚠️ Response is not valid UTF-8")
                print("📄 Raw data: \(data.base64EncodedString())")
            }
            
            // Try to parse response to get server IDs
            if !data.isEmpty {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let response = try decoder.decode(QuickDonationResponse.self, from: data)
                    
                    // Success with response data
                    await MainActor.run {
                        donation.syncStatus = "synced"
                        donation.serverDonationId = response.donorReceiptDetailId
                        donation.errorMessage = nil
                        PersistenceController.shared.save()
                        print("✅ Synced: \(donation.receiptNumber) → Server ID: \(response.donorReceiptDetailId)")
                        print("   Donor: \(response.donorFullName)")
                        print("   Amount: $\(response.donationAmt)")
                        print("📧 Backend automatically sent email receipt")
                    }
                } catch DecodingError.keyNotFound(let key, let context) {
                    print("⚠️ Missing key '\(key.stringValue)' in response")
                    print("   Context: \(context.debugDescription)")
                    print("   Coding path: \(context.codingPath)")
                    await markAsSyncedWithoutId(donation)
                } catch DecodingError.typeMismatch(let type, let context) {
                    print("⚠️ Type mismatch for \(type)")
                    print("   Context: \(context.debugDescription)")
                    await markAsSyncedWithoutId(donation)
                } catch DecodingError.valueNotFound(let type, let context) {
                    print("⚠️ Value not found for \(type)")
                    print("   Context: \(context.debugDescription)")
                    await markAsSyncedWithoutId(donation)
                } catch {
                    print("⚠️ Response parsing failed: \(error.localizedDescription)")
                    await markAsSyncedWithoutId(donation)
                }
            } else {
                // Empty response but 200 status
                await markAsSyncedWithoutId(donation)
            }
            
        } catch {
            // API call failed
            await MainActor.run {
                donation.syncStatus = "failed"
                donation.errorMessage = error.localizedDescription
                
                if donation.syncAttempts >= 3 {
                    donation.syncStatus = "failed_permanent"
                    print("❌ Permanent failure: \(donation.receiptNumber) - \(error.localizedDescription)")
                } else {
                    print("⚠️ Sync failed: \(donation.receiptNumber) - Will retry (Attempt \(donation.syncAttempts)/3)")
                }
                
                PersistenceController.shared.save()
            }
        }
    }

    // Helper function to mark as synced without server ID
    private func markAsSyncedWithoutId(_ donation: OfflineDonation) async {
        await MainActor.run {
            donation.syncStatus = "synced"
            donation.serverDonationId = 0
            donation.errorMessage = nil
            PersistenceController.shared.save()
            print("✅ Synced: \(donation.receiptNumber) (ID unavailable but sync successful)")
            print("📧 Backend automatically sent email receipt")
        }
    }

    
    // MARK: - Convert Offline Donation to API Request (FIXED)
    
    private func convertToOnlineRequest(_ offline: OfflineDonation) -> QuickDonorAndDonationRequest {
        // Improved name splitting logic
        let nameParts = offline.donorName.trimmingCharacters(in: .whitespaces).components(separatedBy: " ")
        let firstName: String
        let lastName: String
        
        if nameParts.count == 1 {
            // Single name - use it for both
            firstName = nameParts[0]
            lastName = nameParts[0]
        } else if nameParts.count == 2 {
            // First and Last
            firstName = nameParts[0]
            lastName = nameParts[1]
        } else {
            // Multiple parts - first is firstName, rest is lastName
            firstName = nameParts[0]
            lastName = nameParts.dropFirst().joined(separator: " ")
        }
        
        let donor = QuickDonorDto(
            firstName: firstName,
            lastName: lastName,
            phone: offline.donorPhone,
            email: offline.donorEmail,
            address1: offline.address1,
            address2: offline.address2,
            city: offline.city,
            state: offline.state,
            country: offline.country,
            postalCode: offline.postalCode,
            isOrganization: offline.isOrganization,
            organizationName: offline.organizationName,
            donorType: offline.donorType
        )
        
        let donation = QuickDonationDto(
            donationAmt: offline.amount.doubleValue,
            donationType: offline.donationType,
            dateOfDonation: offline.createdAt,
            paymentMode: offline.paymentMethod,
            referenceNo: offline.paymentReference,  // FIXED: Use payment reference, not receipt number
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
    
    func retryAllFailedDonations() {
        let failedDonations = getFailedDonations()
        
        guard failedDonations.count > 0 else {
            print("✅ No failed donations to retry")
            return
        }
        
        print("🔄 Retrying \(failedDonations.count) failed donation(s)")
        
        for donation in failedDonations {
            donation.syncStatus = "pending"
            donation.errorMessage = nil
            donation.syncAttempts = 0  // Reset attempts
        }
        
        PersistenceController.shared.save()
        updatePendingCounts()
        
        if isOnline {
            syncAllPendingData()
        }
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
    
    func getDonation(byId id: UUID) -> OfflineDonation? {
        let fetchRequest: NSFetchRequest<OfflineDonation> = OfflineDonation.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        return try? context.fetch(fetchRequest).first
    }
    
    // MARK: - Validation
    
    func validateDonation(_ donation: OfflineDonation) -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []
        
        // Validate donor name
        if donation.donorName.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Donor name is required")
        }
        
        // Validate amount
        if donation.amount.doubleValue <= 0 {
            errors.append("Amount must be greater than zero")
        }
        
        // Validate email format if provided
        if let email = donation.donorEmail, !email.isEmpty {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: email) {
                errors.append("Invalid email format")
            }
        }
        
        // Validate phone format if provided
        if let phone = donation.donorPhone, !phone.isEmpty {
            let digitsOnly = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if digitsOnly.count < 10 {
                errors.append("Phone number must have at least 10 digits")
            }
        }
        
        // Validate organization fields
        if donation.isOrganization {
            if let orgName = donation.organizationName, orgName.trimmingCharacters(in: .whitespaces).isEmpty {
                errors.append("Organization name is required for organization donations")
            }
        }
        
        return (errors.isEmpty, errors)
    }
    
    
    // MARK: - Helper Methods (MISSING SECTION - ADD THIS)
    
    func updatePendingCounts() {
        let donationFetchRequest: NSFetchRequest<OfflineDonation> = OfflineDonation.fetchRequest()
        donationFetchRequest.predicate = NSPredicate(format: "syncStatus == %@ OR syncStatus == %@", "pending", "failed")
        pendingSyncCount = (try? context.count(for: donationFetchRequest)) ?? 0
        
        print("📊 Pending sync count: \(pendingSyncCount)")
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
    
    func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSNumber) ?? "$0.00"
    }

    
    // MARK: - Export/Import (for backup/debugging)
    
    func exportDonationsToJSON() -> String? {
        let donations = getAllDonations()
        
        let exportData = donations.map { donation -> [String: Any] in
            return [
                "id": donation.id.uuidString,
                "receiptNumber": donation.receiptNumber,
                "donorName": donation.donorName,
                "donorEmail": donation.donorEmail ?? "",
                "donorPhone": donation.donorPhone ?? "",
                "amount": donation.amount.doubleValue,
                "donationType": donation.donationType,
                "paymentMethod": donation.paymentMethod,
                "paymentReference": donation.paymentReference ?? "",
                "notes": donation.notes ?? "",
                "createdAt": ISO8601DateFormatter().string(from: donation.createdAt),
                "syncStatus": donation.syncStatus,
                "isOrganization": donation.isOrganization,
                "organizationName": donation.organizationName ?? "",
                "address1": donation.address1 ?? "",
                "address2": donation.address2 ?? "",
                "city": donation.city ?? "",
                "state": donation.state ?? "",
                "country": donation.country ?? "",
                "postalCode": donation.postalCode ?? ""
            ]
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted) {
            return String(data: jsonData, encoding: .utf8)
        }
        
        return nil
    }
    
    // MARK: - Force Sync (Manual)
        
        func forceSyncNow() {
            if isOnline {
                print("🔄 Force sync triggered by user")
                syncAllPendingData()
            } else {
                print("⚠️ Cannot force sync - device is offline")
            }
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
        default: return syncStatus.capitalized
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
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    var donorDisplayName: String {
        if isOrganization, let orgName = organizationName, !orgName.isEmpty {
            return "\(orgName) (Organization)"
        }
        return donorName
    }
    
    var hasContactInfo: Bool {
        return (donorEmail != nil && !donorEmail!.isEmpty) || (donorPhone != nil && !donorPhone!.isEmpty)
    }
    
    var hasAddress: Bool {
        return address1 != nil && !address1!.isEmpty
    }
    
    var fullAddress: String {
        var parts: [String] = []
        
        if let addr1 = address1, !addr1.isEmpty { parts.append(addr1) }
        if let addr2 = address2, !addr2.isEmpty { parts.append(addr2) }
        if let city = city, !city.isEmpty { parts.append(city) }
        if let state = state, !state.isEmpty { parts.append(state) }
        if let zip = postalCode, !zip.isEmpty { parts.append(zip) }
        if let country = country, !country.isEmpty { parts.append(country) }
        
        return parts.joined(separator: ", ")
    }
    
    var paymentInfo: String {
        if let ref = paymentReference, !ref.isEmpty {
            return "\(paymentMethod) - Ref: \(ref)"
        }
        return paymentMethod
    }
    
}
