//
// PersistenceController.swift
// RAMA_TMS
//
// Created by Tejasvi Mahesh on 1/2/26.
// Core Data Stack with Programmatic Model
// Updated: 1/3/26 - Added complete field support for offline donations
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
        
        // Add entities to model
        model.entities = [donationEntity]
        
        return model
    }
    
    // MARK: - OfflineDonation Entity (UPDATED with ALL fields)
    
    private static func createDonationEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "OfflineDonation"
        entity.managedObjectClassName = "OfflineDonation"
        
        var properties: [NSAttributeDescription] = []
        
        // Core identification
        properties.append(createAttribute(name: "id", type: .UUIDAttributeType, isOptional: false))
        properties.append(createAttribute(name: "receiptNumber", type: .stringAttributeType, isOptional: false))
        properties.append(createAttribute(name: "createdAt", type: .dateAttributeType, isOptional: false))
        
        // Donor information
        properties.append(createAttribute(name: "donorName", type: .stringAttributeType, isOptional: false))
        properties.append(createAttribute(name: "donorEmail", type: .stringAttributeType, isOptional: true))
        properties.append(createAttribute(name: "donorPhone", type: .stringAttributeType, isOptional: true))
        
        // ✅ NEW: Address fields (fixes Bug #1)
        properties.append(createAttribute(name: "address1", type: .stringAttributeType, isOptional: true))
        properties.append(createAttribute(name: "address2", type: .stringAttributeType, isOptional: true))
        properties.append(createAttribute(name: "city", type: .stringAttributeType, isOptional: true))
        properties.append(createAttribute(name: "state", type: .stringAttributeType, isOptional: true))
        properties.append(createAttribute(name: "country", type: .stringAttributeType, isOptional: true))
        properties.append(createAttribute(name: "postalCode", type: .stringAttributeType, isOptional: true))
        
        // ✅ NEW: Organization fields (fixes Bug #2)
        properties.append(createAttribute(name: "isOrganization", type: .booleanAttributeType, isOptional: false, defaultValue: false))
        properties.append(createAttribute(name: "organizationName", type: .stringAttributeType, isOptional: true))
        properties.append(createAttribute(name: "donorType", type: .stringAttributeType, isOptional: false, defaultValue: "Individual"))
        
        // Donation details
        properties.append(createAttribute(name: "amount", type: .decimalAttributeType, isOptional: false))
        properties.append(createAttribute(name: "donationType", type: .stringAttributeType, isOptional: false, defaultValue: "General"))
        properties.append(createAttribute(name: "paymentMethod", type: .stringAttributeType, isOptional: false, defaultValue: "Cash"))
        properties.append(createAttribute(name: "paymentReference", type: .stringAttributeType, isOptional: true))  // ✅ NEW (fixes Bug #3)
        properties.append(createAttribute(name: "notes", type: .stringAttributeType, isOptional: true))
        
        // Collection tracking
        properties.append(createAttribute(name: "collectorEmail", type: .stringAttributeType, isOptional: false))
        
        // Sync management
        properties.append(createAttribute(name: "syncStatus", type: .stringAttributeType, isOptional: false, defaultValue: "pending"))
        properties.append(createAttribute(name: "syncAttempts", type: .integer16AttributeType, isOptional: false, defaultValue: 0))
        properties.append(createAttribute(name: "lastSyncAttempt", type: .dateAttributeType, isOptional: true))
        properties.append(createAttribute(name: "serverDonationId", type: .integer64AttributeType, isOptional: false, defaultValue: 0))
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
                   print("❌ Error saving context: \(error.localizedDescription)")  // ✅ FIXED: Added closing quote
               }
           }
       }
    
    // MARK: - Clear All Data (for testing)
    
    func clearAllData() {
        let context = container.viewContext
        
        // Delete all OfflineDonations
        let donationFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "OfflineDonation")
        let deleteDonationRequest = NSBatchDeleteRequest(fetchRequest: donationFetchRequest)
        
        do {
            try context.execute(deleteDonationRequest)
            try context.save()
            print("✅ All offline data cleared")
        } catch {
            print("❌ Error clearing data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Get Statistics
    
    func getStats() -> (donations: Int, pendingSync: Int) {
        let context = container.viewContext
        
        // Total donations
        let donationFetchRequest: NSFetchRequest<OfflineDonation> = OfflineDonation.fetchRequest()
        let totalDonations = (try? context.count(for: donationFetchRequest)) ?? 0
        
        // Pending sync
        donationFetchRequest.predicate = NSPredicate(format: "syncStatus == %@ OR syncStatus == %@", "pending", "failed")
        let pendingSync = (try? context.count(for: donationFetchRequest)) ?? 0
        
        return (totalDonations, pendingSync)
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
            donation.donorPhone = "555-000-100\(i)"
            donation.address1 = "\(i)00 Main Street"
            donation.city = "Atlanta"
            donation.state = "GA"
            donation.country = "USA"
            donation.postalCode = "3030\(i)"
            donation.isOrganization = i % 3 == 0
            donation.organizationName = i % 3 == 0 ? "Organization \(i)" : nil
            donation.donorType = i % 3 == 0 ? "Organization" : "Individual"
            donation.amount = NSDecimalNumber(value: Double(i * 100))
            donation.donationType = "General"
            donation.paymentMethod = i % 2 == 0 ? "Check" : "Cash"
            donation.paymentReference = i % 2 == 0 ? "CHK-\(i)000" : nil
            donation.receiptNumber = "OFF-\(Int(Date().timeIntervalSince1970))-\(i)000"
            donation.createdAt = Date()
            donation.collectorEmail = "collector@temple.com"
            donation.syncStatus = i % 2 == 0 ? "pending" : "synced"
            donation.syncAttempts = 0
        }
        
        do {
            try context.save()
        } catch {
            print("Error creating preview data: \(error)")
        }
        
        return controller
    }()
}

