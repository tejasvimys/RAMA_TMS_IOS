//
//  PersistenceController.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 1/2/26.
//  Core Data Stack with Programmatic Model
//

import CoreData
import Foundation

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        // Create managed object model programmatically
        let model = PersistenceController.createModel()
        container = NSPersistentContainer(name: "RAMA_TMS", managedObjectModel: model)
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                // If store is incompatible, delete and recreate
                if let storeURL = description.url {
                    try? FileManager.default.removeItem(at: storeURL)
                    
                    // Try loading again
                    self.container.loadPersistentStores { _, loadError in
                        if let loadError = loadError {
                            fatalError("Unable to load persistent stores: \(loadError)")
                        }
                    }
                } else {
                    fatalError("Unable to load persistent stores: \(error)")
                }
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Create Core Data Model Programmatically
    
    private static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // Create OfflineDonation Entity
        let donationEntity = createDonationEntity()
        
        // Create EmailQueue Entity
        let emailEntity = createEmailQueueEntity()
        
        // Add entities to model
        model.entities = [donationEntity, emailEntity]
        
        return model
    }
    
    // MARK: - OfflineDonation Entity
    
    private static func createDonationEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "OfflineDonation"
        entity.managedObjectClassName = "OfflineDonation"
        
        var properties: [NSAttributeDescription] = []
        
        // id - UUID
        properties.append(createAttribute(name: "id", type: .UUIDAttributeType, isOptional: false))
        
        // donorName - String
        properties.append(createAttribute(name: "donorName", type: .stringAttributeType, isOptional: false))
        
        // donorEmail - String (Optional)
        properties.append(createAttribute(name: "donorEmail", type: .stringAttributeType, isOptional: true))
        
        // donorPhone - String (Optional)
        properties.append(createAttribute(name: "donorPhone", type: .stringAttributeType, isOptional: true))
        
        // amount - Decimal
        properties.append(createAttribute(name: "amount", type: .decimalAttributeType, isOptional: false))
        
        // donationType - String
        properties.append(createAttribute(name: "donationType", type: .stringAttributeType, isOptional: false, defaultValue: "One-time"))
        
        // paymentMethod - String
        properties.append(createAttribute(name: "paymentMethod", type: .stringAttributeType, isOptional: false, defaultValue: "Cash"))
        
        // notes - String (Optional)
        properties.append(createAttribute(name: "notes", type: .stringAttributeType, isOptional: true))
        
        // receiptNumber - String
        properties.append(createAttribute(name: "receiptNumber", type: .stringAttributeType, isOptional: false))
        
        // createdAt - Date
        properties.append(createAttribute(name: "createdAt", type: .dateAttributeType, isOptional: false))
        
        // collectorEmail - String
        properties.append(createAttribute(name: "collectorEmail", type: .stringAttributeType, isOptional: false))
        
        // syncStatus - String
        properties.append(createAttribute(name: "syncStatus", type: .stringAttributeType, isOptional: false, defaultValue: "pending"))
        
        // syncAttempts - Integer 16
        properties.append(createAttribute(name: "syncAttempts", type: .integer16AttributeType, isOptional: false, defaultValue: 0))
        
        // lastSyncAttempt - Date (Optional)
        properties.append(createAttribute(name: "lastSyncAttempt", type: .dateAttributeType, isOptional: true))
        
        // serverDonationId - Integer 64
        properties.append(createAttribute(name: "serverDonationId", type: .integer64AttributeType, isOptional: false, defaultValue: 0))
        
        // errorMessage - String (Optional)
        properties.append(createAttribute(name: "errorMessage", type: .stringAttributeType, isOptional: true))
        
        // needsEmailReceipt - Boolean
        properties.append(createAttribute(name: "needsEmailReceipt", type: .booleanAttributeType, isOptional: false, defaultValue: false))
        
        entity.properties = properties
        return entity
    }
    
    // MARK: - EmailQueue Entity
    
    private static func createEmailQueueEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "EmailQueue"
        entity.managedObjectClassName = "EmailQueue"
        
        var properties: [NSAttributeDescription] = []
        
        // id - UUID
        properties.append(createAttribute(name: "id", type: .UUIDAttributeType, isOptional: false))
        
        // recipientEmail - String
        properties.append(createAttribute(name: "recipientEmail", type: .stringAttributeType, isOptional: false))
        
        // subject - String
        properties.append(createAttribute(name: "subject", type: .stringAttributeType, isOptional: false))
        
        // body - String
        properties.append(createAttribute(name: "body", type: .stringAttributeType, isOptional: false))
        
        // receiptNumber - String
        properties.append(createAttribute(name: "receiptNumber", type: .stringAttributeType, isOptional: false))
        
        // donationId - UUID
        properties.append(createAttribute(name: "donationId", type: .UUIDAttributeType, isOptional: false))
        
        // createdAt - Date
        properties.append(createAttribute(name: "createdAt", type: .dateAttributeType, isOptional: false))
        
        // sendAttempts - Integer 16
        properties.append(createAttribute(name: "sendAttempts", type: .integer16AttributeType, isOptional: false, defaultValue: 0))
        
        // lastAttempt - Date (Optional)
        properties.append(createAttribute(name: "lastAttempt", type: .dateAttributeType, isOptional: true))
        
        // status - String
        properties.append(createAttribute(name: "status", type: .stringAttributeType, isOptional: false, defaultValue: "pending"))
        
        // errorMessage - String (Optional)
        properties.append(createAttribute(name: "errorMessage", type: .stringAttributeType, isOptional: true))
        
        entity.properties = properties
        return entity
    }
    
    // MARK: - Helper Method to Create Attributes
    
    private static func createAttribute(
        name: String,
        type: NSAttributeType,
        isOptional: Bool,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = isOptional
        
        if let defaultValue = defaultValue {
            attribute.defaultValue = defaultValue
        }
        
        return attribute
    }
    
    // MARK: - Save Context
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ Error saving context: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Clear All Data (for testing)
    
    func clearAllData() {
        let context = container.viewContext
        
        // Delete all OfflineDonations
        let donationFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "OfflineDonation")
        let deleteDonationRequest = NSBatchDeleteRequest(fetchRequest: donationFetchRequest)
        
        // Delete all EmailQueue
        let emailFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "EmailQueue")
        let deleteEmailRequest = NSBatchDeleteRequest(fetchRequest: emailFetchRequest)
        
        do {
            try context.execute(deleteDonationRequest)
            try context.execute(deleteEmailRequest)
            try context.save()
            print("✅ All offline data cleared")
        } catch {
            print("❌ Error clearing data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Get Statistics
    
    func getStats() -> (donations: Int, pendingSync: Int, pendingEmails: Int) {
        let context = container.viewContext
        
        // Total donations
        let donationFetchRequest: NSFetchRequest<OfflineDonation> = OfflineDonation.fetchRequest()
        let totalDonations = (try? context.count(for: donationFetchRequest)) ?? 0
        
        // Pending sync
        donationFetchRequest.predicate = NSPredicate(format: "syncStatus == %@ OR syncStatus == %@", "pending", "failed")
        let pendingSync = (try? context.count(for: donationFetchRequest)) ?? 0
        
        // Pending emails
        let emailFetchRequest: NSFetchRequest<EmailQueue> = EmailQueue.fetchRequest()
        emailFetchRequest.predicate = NSPredicate(format: "status == %@ OR status == %@", "pending", "failed")
        let pendingEmails = (try? context.count(for: emailFetchRequest)) ?? 0
        
        return (totalDonations, pendingSync, pendingEmails)
    }
}

// MARK: - Preview Helper

extension PersistenceController {
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // Create sample data for previews
        for i in 1...5 {
            let donation = OfflineDonation(context: context)
            donation.id = UUID()
            donation.donorName = "Sample Donor \(i)"
            donation.donorEmail = "donor\(i)@example.com"
            donation.amount = NSDecimalNumber(value: Double(i * 100))
            donation.donationType = "One-time"
            donation.paymentMethod = "Cash"
            donation.receiptNumber = "OFF-\(Date().timeIntervalSince1970)-\(i)"
            donation.createdAt = Date()
            donation.collectorEmail = "collector@temple.com"
            donation.syncStatus = i % 2 == 0 ? "pending" : "synced"
            donation.syncAttempts = 0
            donation.needsEmailReceipt = i % 3 == 0
        }
        
        do {
            try context.save()
        } catch {
            print("Error creating preview data: \(error)")
        }
        
        return controller
    }()
}
