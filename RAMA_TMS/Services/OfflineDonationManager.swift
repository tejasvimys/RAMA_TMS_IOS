//
// OfflineDonationManager.swift
// RAMA_TMS
//
// Manages offline donation storage and syncing
//

import Foundation
import CoreData
import Combine

class OfflineDonationManager: ObservableObject {
    static let shared = OfflineDonationManager()
    
    private let context: NSManagedObjectContext
    @Published var pendingSyncCount: Int = 0
    @Published var isSyncing: Bool = false
    
    private init() {
        self.context = PersistenceController.shared.container.viewContext
        updatePendingCount()
    }
    
    // MARK: - Save Offline Donation
    
    func saveDonation(
        donorName: String,
        donorEmail: String?,
        donorPhone: String?,
        amount: Double,
        donationType: String,
        paymentMethod: String,
        notes: String?,
        collectorEmail: String
    ) throws -> OfflineDonation {
        let donation = OfflineDonation(context: context)
        
        // Map fields
        donation.donorName = donorName
        donation.donorEmail = donorEmail
        donation.donorPhone = donorPhone
        donation.amount = NSDecimalNumber(value: amount)
        donation.donationType = donationType
        donation.paymentMethod = paymentMethod
        donation.notes = notes
        donation.collectorEmail = collectorEmail
        donation.receiptNumber = generateReceiptNumber()
        donation.createdAt = Date()
        donation.syncStatus = "pending"
        
        try context.save()
        updatePendingCount()
        
        print("✅ Saved offline donation: \(donation.receiptNumber)")
        return donation
    }
    
    // MARK: - Sync to Backend
    
    func syncPendingDonations() async {
        guard !isSyncing else { return }
        
        await MainActor.run { isSyncing = true }
        defer { Task { await MainActor.run { isSyncing = false } } }
        
        let pending = fetchPendingDonations()
        print("🔄 Syncing \(pending.count) pending donations...")
        
        for donation in pending {
            await syncSingleDonation(donation)
        }
        
        await MainActor.run { updatePendingCount() }
    }
    
    private func syncSingleDonation(_ donation: OfflineDonation) async {
        // Update status
        donation.syncStatus = "syncing"
        donation.lastSyncAttempt = Date()
        try? context.save()
        
        do {
            // Convert to API request
            let request = convertToOnlineRequest(donation)
            
            // Call backend API - IT WILL SEND THE EMAIL AUTOMATICALLY
            let data = try await QuickDonationApi.shared.submitQuickDonation(request)
            
            // Parse response to get server IDs
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let response = try decoder.decode(QuickDonationResponse.self, from: data)
            
            // Mark as synced
            donation.syncStatus = "synced"
            donation.serverDonationId = response.donorReceiptDetailId
            donation.errorMessage = nil
            
            print("✅ Synced donation \(donation.receiptNumber) → Server ID: \(response.donorReceiptDetailId)")
            print("📧 Backend automatically sent email receipt to: \(donation.donorEmail ?? "N/A")")
            
        } catch {
            // Handle sync failure
            donation.syncStatus = "failed"
            donation.syncAttempts += 1
            donation.errorMessage = error.localizedDescription
            
            print("❌ Failed to sync \(donation.receiptNumber): \(error)")
        }
        
        try? context.save()
    }
    
    // MARK: - Convert to API Request
    
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
    
    // MARK: - Fetch & Query
    
    func fetchPendingDonations() -> [OfflineDonation] {
        let request = OfflineDonation.fetchRequest()
        request.predicate = NSPredicate(format: "syncStatus == %@", "pending")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \OfflineDonation.createdAt, ascending: true)]
        
        return (try? context.fetch(request)) ?? []
    }
    
    func fetchAllDonations() -> [OfflineDonation] {
        let request = OfflineDonation.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \OfflineDonation.createdAt, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
    
    func updatePendingCount() {
        pendingSyncCount = fetchPendingDonations().count
    }
    
    // MARK: - Helper
    
    private func generateReceiptNumber() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let random = Int.random(in: 1000...9999)
        return "OFF-\(timestamp)-\(random)"
    }
}

