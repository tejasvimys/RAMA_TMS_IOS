//
//  QuickDonationApi.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/21/25.
//

import Foundation

final class QuickDonationApi {
    static let shared = QuickDonationApi()
        
    private let baseUrl = URL(string: "http://10.0.0.3:5158")!
    
    private init() {}
    
    private func makeAuthRequest(path: String, method: String) -> URLRequest {
        let url = baseUrl.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Attach JWT from UserDefaults
        if let token = UserDefaults.standard.string(forKey: "appToken") {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 Attaching token: \(token.prefix(20))...")
        } else {
            print("⚠️ No token found in UserDefaults")
        }
        
        return req
    }
    
    func submitQuickDonation(_ requestBody: QuickDonorAndDonationRequest) async throws -> Data {
        var req = makeAuthRequest(path: "/api/donorreceipts/quick-with-receipt", method: "POST")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        req.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: req)
        
        print("📥 Quick donation response: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("❌ Error body: \(body)")
            throw NSError(domain: "QuickDonationApi", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "API error: \(body)"])
        }

        return data
    }
    
    func getMyDonations() async throws -> [MobileDonationListItem] {
        let req = makeAuthRequest(path: "/api/mobile/donations/donations", method: "GET")
        
        print("🌐 Fetching donations from: \(req.url?.absoluteString ?? "")")
        print("🔑 Authorization header: \(req.value(forHTTPHeaderField: "Authorization")?.prefix(30) ?? "none")...")
        
        let (data, response) = try await URLSession.shared.data(for: req)
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        print("📥 Donations list response: \(statusCode)")
        print("📦 Response size: \(data.count) bytes")
        
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("❌ Error body: \(body)")
            throw NSError(domain: "QuickDonationApi", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to load donations: \(body)"])
        }
        
        // Log raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📄 Raw JSON response: \(jsonString)")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let items = try decoder.decode([MobileDonationListItem].self, from: data)
        print("✅ Loaded \(items.count) donations")
        
        return items
    }
    
    func getTodaySummary() async throws -> DaySummaryDto {
        let req = makeAuthRequest(path: "/api/mobile/donations/today", method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: req)
        
        print("📥 Summary response: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "QuickDonationApi", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to load summary: \(body)"])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(DaySummaryDto.self, from: data)
    }
    
    // ✅ Submit donation to mobile endpoint
    func submitQuickDonationMobile(_ requestBody: QuickDonorAndDonationRequest) async throws -> MobileQuickDonationResponse {
        var req = makeAuthRequest(path: "/api/mobile/donations/quick", method: "POST")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        req.httpBody = try encoder.encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: req)
        
        print("📥 Mobile donation response: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("❌ Error body: \(body)")
            throw NSError(domain: "QuickDonationApi", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "API error: \(body)"])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let mobileResponse = try decoder.decode(MobileQuickDonationResponse.self, from: data)
        print("✅ Mobile donation created: Receipt ID \(mobileResponse.donorReceiptDetailId)")
        
        return mobileResponse
    }

    // ✅  Download PDF receipt
    func downloadReceiptPdf(receiptId: Int64) async throws -> Data {
        let req = makeAuthRequest(path: "/api/mobile/donations/receipts/\(receiptId)/pdf", method: "GET")
        
        print("📥 Downloading PDF for receipt ID: \(receiptId)")
        
        let (data, response) = try await URLSession.shared.data(for: req)
        
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("❌ PDF download error: \(body)")
            throw NSError(domain: "QuickDonationApi", code: 5,
                userInfo: [NSLocalizedDescriptionKey: "Failed to download PDF: \(body)"])
        }
        
        print("✅ PDF downloaded: \(data.count) bytes")
        return data
    }
}

