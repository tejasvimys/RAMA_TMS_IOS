//
// CoreDataModels.swift
// RAMA_TMS
//
// Created by Tejasvi Mahesh on 1/2/26.
// Programmatic Core Data Models
//

import Foundation
import CoreData

// MARK: - Offline Donation Entity

@objc(OfflineDonation)
public class OfflineDonation: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var donorName: String
    @NSManaged public var donorEmail: String?
    @NSManaged public var donorPhone: String?
    @NSManaged public var amount: NSDecimalNumber
    @NSManaged public var donationType: String
    @NSManaged public var paymentMethod: String
    @NSManaged public var notes: String?
    @NSManaged public var receiptNumber: String
    @NSManaged public var createdAt: Date
    @NSManaged public var collectorEmail: String
    @NSManaged public var syncStatus: String // pending, syncing, synced, failed
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
    }
}

