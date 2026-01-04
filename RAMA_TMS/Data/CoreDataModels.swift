//
// CoreDataModels.swift
// RAMA_TMS
//
// Created by Tejasvi Mahesh on 1/2/26.
// Programmatic Core Data Models
// Updated: 1/3/26 - Added complete field mapping for offline sync
//

import Foundation
import CoreData

// MARK: - Offline Donation Entity

@objc(OfflineDonation)
public class OfflineDonation: NSManagedObject {
    // Core identification
    @NSManaged public var id: UUID
    @NSManaged public var receiptNumber: String
    @NSManaged public var createdAt: Date
    
    // Donor information
    @NSManaged public var donorName: String
    @NSManaged public var donorEmail: String?
    @NSManaged public var donorPhone: String?
    
    // Donor address (NEW - fixes Bug #1)
    @NSManaged public var address1: String?
    @NSManaged public var address2: String?
    @NSManaged public var city: String?
    @NSManaged public var state: String?
    @NSManaged public var country: String?
    @NSManaged public var postalCode: String?
    
    // Organization support (NEW - fixes Bug #2)
    @NSManaged public var isOrganization: Bool
    @NSManaged public var organizationName: String?
    @NSManaged public var donorType: String
    
    // Donation details
    @NSManaged public var amount: NSDecimalNumber
    @NSManaged public var donationType: String
    @NSManaged public var paymentMethod: String
    @NSManaged public var paymentReference: String?  // NEW - fixes Bug #3
    @NSManaged public var notes: String?
    
    // Collection tracking
    @NSManaged public var collectorEmail: String
    
    // Sync management
    @NSManaged public var syncStatus: String // pending, syncing, synced, failed, failed_permanent
    @NSManaged public var syncAttempts: Int16
    @NSManaged public var lastSyncAttempt: Date?
    @NSManaged public var serverDonationId: Int64
    @NSManaged public var errorMessage: String?
}

extension OfflineDonation {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<OfflineDonation> {
        return NSFetchRequest<OfflineDonation>(entityName: "OfflineDonation")
    }
    
    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "OfflineDonation", in: context)!
        self.init(entity: entity, insertInto: context)
        
        // Set defaults
        self.id = UUID()
        self.createdAt = Date()
        self.syncStatus = "pending"
        self.syncAttempts = 0
        self.serverDonationId = 0
        self.isOrganization = false
        self.donorType = "Individual"
    }
}

