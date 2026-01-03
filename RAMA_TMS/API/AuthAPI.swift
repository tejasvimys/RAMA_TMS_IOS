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
    
    private let baseUrl = URL(string: APIConfig.baseURL)!
    
    private init() {}
    
    // MARK: - Authentication Methods
    
    func login(email: String, password: String) async throws -> LoginWith2FAResponse {
        let url = baseUrl.appendingPathComponent("/api/auth/login")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = LoginRequest(email: email, password: password)
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Login failed"
            throw NSError(domain: "AuthAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        return try JSONDecoder().decode(LoginWith2FAResponse.self, from: data)
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
    
    // MARK: - 2FA Methods (Login Flow Only)
    
    func verify2FA(email: String, code: String, tempToken: String) async throws -> TokenExchangeResponse {
        let url = baseUrl.appendingPathComponent("/api/auth/verify-2fa")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = Verify2FARequest(email: email, code: code, tempToken: tempToken)
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Invalid 2FA code"
            throw NSError(domain: "AuthAPI", code: 4, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        return try JSONDecoder().decode(TokenExchangeResponse.self, from: data)
    }
    
    func enable2FAFirstTime(password: String, tempToken: String) async throws -> Enable2FAResponse {
        let url = baseUrl.appendingPathComponent("/api/auth/2fa/enable")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(tempToken)", forHTTPHeaderField: "Authorization")
        
        let body = Enable2FARequest(password: password)
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Failed to enable 2FA"
            throw NSError(domain: "AuthAPI", code: 5, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        return try JSONDecoder().decode(Enable2FAResponse.self, from: data)
    }
    
    func verify2FASetup(code: String, tempToken: String) async throws -> String {
        let url = baseUrl.appendingPathComponent("/api/auth/2fa/verify-setup")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(tempToken)", forHTTPHeaderField: "Authorization")
        
        let body = Verify2FASetupRequest(code: code)
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Invalid code"
            throw NSError(domain: "AuthAPI", code: 6, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        let result = try JSONDecoder().decode(MessageResponse.self, from: data)
        return result.message
    }
    
    // MARK: - Password Reset Methods

    func forgotPassword(email: String) async throws -> ForgotPasswordResponse {
        let url = baseUrl.appendingPathComponent("/api/password-reset/forgot-password")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ForgotPasswordRequest(email: email)
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Failed to send reset email"
            throw NSError(domain: "AuthAPI", code: 7, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        return try JSONDecoder().decode(ForgotPasswordResponse.self, from: data)
    }

    func validateResetToken(token: String) async throws -> ValidateResetTokenResponse {
        let url = baseUrl.appendingPathComponent("/api/password-reset/validate-token")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ValidateResetTokenRequest(token: token)
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Invalid or expired token"
            throw NSError(domain: "AuthAPI", code: 8, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        return try JSONDecoder().decode(ValidateResetTokenResponse.self, from: data)
    }

    func resetPassword(token: String, newPassword: String) async throws -> String {
        let url = baseUrl.appendingPathComponent("/api/password-reset/reset-password")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ResetPasswordRequest(token: token, newPassword: newPassword)
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Failed to reset password"
            throw NSError(domain: "AuthAPI", code: 9, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        let result = try JSONDecoder().decode(ResetPasswordResponse.self, from: data)
        return result.message
    }
    // MARK: - Health Check

    func checkHealth() async throws -> HealthStatus {
        let url = baseUrl.appendingPathComponent("/api/health")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 10 // 10 second timeout
        
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            
            guard let http = response as? HTTPURLResponse else {
                return .networkError
            }
            
            if http.statusCode == 200 {
                let healthResponse = try? JSONDecoder().decode(HealthCheckResponse.self, from: data)
                if healthResponse?.status == "healthy" {
                    return .healthy
                } else {
                    return .unhealthy(message: healthResponse?.message ?? "Unknown error")
                }
            } else {
                let healthResponse = try? JSONDecoder().decode(HealthCheckResponse.self, from: data)
                return .unhealthy(message: healthResponse?.message ?? "Server error")
            }
        } catch let error as NSError {
            if error.domain == NSURLErrorDomain {
                switch error.code {
                case NSURLErrorTimedOut:
                    return .timeout
                case NSURLErrorCannotConnectToHost,
                     NSURLErrorCannotFindHost,
                     NSURLErrorNotConnectedToInternet:
                    return .networkError
                default:
                    return .networkError
                }
            }
            return .networkError
        }
    }
}





