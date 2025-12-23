//
//  EndOfDayAPI.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/23/25.
//

import Foundation

final class EndOfDayAPI {
    static let shared = EndOfDayAPI()
    
    private let baseUrl = URL(string: "http://10.0.0.3:5158")!
    
    private init() {}
    
    private func makeAuthRequest(url: URL, method: String) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Attach JWT from UserDefaults
        if let token = UserDefaults.standard.string(forKey: "appToken") {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 [EOD] Attaching token: \(token.prefix(20))...")
        } else {
            print("⚠️ [EOD] No token found in UserDefaults")
        }
        
        return req
    }
    

    func getReport(for date: Date) async throws -> EndOfDayReport {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        // Build URL with query parameters correctly
        var components = URLComponents(url: baseUrl.appendingPathComponent("/api/reports/end-of-day"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "date", value: dateString)]
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        let req = makeAuthRequest(url: url, method: "GET")
        
        print("🌐 [EOD] Fetching report from: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: req)
        
        print("📥 [EOD] Report response: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Log response body for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 [EOD] Response body: \(responseString)")
        }
        
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("❌ [EOD] Error body: \(body)")
            
            if http.statusCode == 401 || http.statusCode == 403 {
                throw APIError.unauthorized
            } else if http.statusCode == 404 {
                throw APIError.noData
            } else {
                throw NSError(domain: "EndOfDayAPI", code: http.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: "Failed to load report: \(body)"])
            }
        }
        
        let decoder = JSONDecoder()
        // Use custom date decoder to handle multiple formats
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 with timezone first
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            // Try ISO8601 without timezone
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            // Try basic format: "2025-12-22T00:00:00"
            let basicFormatter = DateFormatter()
            basicFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            basicFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = basicFormatter.date(from: dateString) {
                return date
            }
            
            // Try date only format: "2025-12-22"
            basicFormatter.dateFormat = "yyyy-MM-dd"
            if let date = basicFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        
        do {
            let report = try decoder.decode(EndOfDayReport.self, from: data)
            print("✅ [EOD] Report loaded successfully")
            return report
        } catch {
            print("❌ [EOD] Decoding error: \(error)")
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    
    
    func sendReportEmail(date: Date) async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let url = baseUrl.appendingPathComponent("/api/reports/send-email")
        var req = makeAuthRequest(url: url, method: "POST")
        
        let payload: [String: String] = ["date": dateString]
        let encoder = JSONEncoder()
        req.httpBody = try encoder.encode(payload)
        
        print("📧 [EOD] Sending email request for date: \(dateString)")
        print("📧 [EOD] URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: req)
        
        print("📥 [EOD] Email response: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("❌ [EOD] Error body: \(body)")
            
            if http.statusCode == 401 || http.statusCode == 403 {
                throw APIError.unauthorized
            } else if http.statusCode == 404 {
                throw APIError.noData
            } else {
                throw NSError(domain: "EndOfDayAPI", code: http.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: "Failed to send email: \(body)"])
            }
        }
        
        print("✅ [EOD] Email sent successfully")
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case noData
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Authentication failed. Please login again."
        case .noData:
            return "No donations found for this date"
        case .decodingError(let message):
            return "Failed to parse response: \(message)"
        }
    }
}

