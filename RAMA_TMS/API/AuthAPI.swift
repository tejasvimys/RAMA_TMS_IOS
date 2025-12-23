//
//  AuthAPI.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/22/25.
//

import Foundation

struct TokenExchangeRequest: Codable {
    let provider: String
    let idToken: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let displayName: String
    let password: String
}

struct TokenExchangeResponse: Codable {
    let appToken: String?
    let email: String
    let displayName: String
    let role: String?
    let isActive: Bool
    let isNewUser: Bool?
}

final class AuthAPI {
    static let shared = AuthAPI()
    
    // Replace with your backend URL
    private let baseUrl = URL(string: APIConfig.baseURL)!
    //private let baseUrl = URL(string: "https://10.0.0.3:7181")!
    
    private init() {}
    
    func exchangeGoogleToken(_ idToken: String) async throws -> TokenExchangeResponse {
        let url = baseUrl.appendingPathComponent("/api/auth/exchange")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = TokenExchangeRequest(provider: "google", idToken: idToken)
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "AuthAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Exchange failed"])
        }
        
        return try JSONDecoder().decode(TokenExchangeResponse.self, from: data)
    }
    
//    func login(email: String, password: String) async throws -> TokenExchangeResponse {
//        let url = baseUrl.appendingPathComponent("/api/auth/login")
//        var req = URLRequest(url: url)
//        req.httpMethod = "POST"
//        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        let body = LoginRequest(email: email, password: password)
//        req.httpBody = try JSONEncoder().encode(body)
//        
//        let (data, response) = try await URLSession.shared.data(for: req)
//        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
//            throw NSError(domain: "AuthAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Login failed"])
//        }
//        
//        return try JSONDecoder().decode(TokenExchangeResponse.self, from: data)
//    }
    
    func login(email: String, password: String) async throws -> TokenExchangeResponse {
        let url = baseUrl.appendingPathComponent("/api/auth/login")
        
        print("🌐 API URL: \(url.absoluteString)")  // ADD THIS
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = LoginRequest(email: email, password: password)
        req.httpBody = try JSONEncoder().encode(body)
        
        print("📤 Request body: \(String(data: req.httpBody!, encoding: .utf8) ?? "")")  // ADD THIS
        
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            
            print("📥 Response status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")  // ADD THIS
            print("📥 Response body: \(String(data: data, encoding: .utf8) ?? "")")  // ADD THIS
            
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw NSError(domain: "AuthAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Login failed"])
            }
            
            return try JSONDecoder().decode(TokenExchangeResponse.self, from: data)
        } catch {
            print("❌ Error: \(error)")  // ADD THIS
            throw error
        }
    }

    
    func register(email: String, displayName: String, password: String) async throws -> String {
        let url = baseUrl.appendingPathComponent("/api/auth/register")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = RegisterRequest(email: email, displayName: displayName, password: password)
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "AuthAPI", code: 3, userInfo: [NSLocalizedDescriptionKey: "Registration failed"])
        }
        
        let result = try JSONDecoder().decode([String: String].self, from: data)
        return result["message"] ?? "Registered successfully"
    }
}
