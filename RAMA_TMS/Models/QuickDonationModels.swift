//
//  QuickDonationModels.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/21/25.
//

import Foundation

struct QuickDonorDto: Codable {
    var firstName: String
    var lastName: String
    var phone: String?
    var email: String?
    var address1: String?
    var address2: String?
    var city: String?
    var state: String?
    var country: String?
    var postalCode: String?
    var isOrganization: Bool
    var organizationName: String?
    var donorType: String  // "Individual" or "Organization"
}

struct QuickDonationDto: Codable {
    var donationAmt: Double
    var donationType: String
    var dateOfDonation: Date
    var paymentMode: String?
    var referenceNo: String?
    var notes: String?
}

struct QuickDonorAndDonationRequest: Codable {
    var donor: QuickDonorDto
    var donation: QuickDonationDto
}

struct QuickDonationResponse: Codable {
    var donorId: Int64
    var donorReceiptDetailId: Int64
    var donorFullName: String
    var donationAmt: Double
    var dateOfDonation: Date
}
// Mobile donation list
struct MobileDonationListItem: Codable, Identifiable {
    let donorReceiptDetailId: Int64
    let donorId: Int64
    let donorName: String
    let donationAmt: Double
    let donationType: String
    let dateOfDonation: Date
    let paymentMode: String?
    let referenceNo: String?
    let notes: String?
    
    var id: Int64 { donorReceiptDetailId }
}

// Day summary
struct DaySummaryDto: Codable {
    let date: Date
    let totalAmount: Double
    let count: Int
}
struct MobileQuickDonationResponse: Codable {
    var donorId: Int64
    var donorReceiptDetailId: Int64
    var donorFullName: String
    var donationAmt: Double
    var dateOfDonation: Date
    var receiptNumber: String
    var donationType: String
    var paymentMethod: String
    var paymentReference: String?
    var emailSent: Bool
    var receiptPdfUrl: String
}
