//
//  EndOfDayReport.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/23/25.
//

import Foundation

struct EndOfDayReport: Codable, Identifiable {
    let id: String
    let date: Date
    let totalAmount: Double
    let totalCount: Int
    let uniqueDonors: Int
    let averageDonation: Double
    let byDonationType: [DonationTypeBreakdown]
    let byPaymentMethod: [PaymentMethodBreakdown]
    let donations: [DonationDetail]
    let collectorName: String?
    let collectorEmail: String?
    
    var formattedDate: String {
        date.formatted(date: .long, time: .omitted)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case totalAmount
        case totalCount
        case uniqueDonors
        case averageDonation
        case byDonationType
        case byPaymentMethod
        case donations
        case collectorName
        case collectorEmail
    }
}

struct DonationTypeBreakdown: Codable, Identifiable {
    var id: String { type }
    let type: String
    let amount: Double
    let count: Int
}

struct PaymentMethodBreakdown: Codable, Identifiable {
    var id: String { type }
    let type: String
    let amount: Double
    let count: Int
}

struct DonationDetail: Codable, Identifiable {
    let id: String
    let donorName: String
    let amount: Double
    let donationType: String
    let paymentMode: String
    let referenceNo: String?
    let timestamp: Date
    let notes: String?
}
