//
//  TwoFactorModels.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 1/2/26.
//  Created for 2FA Implementation
//

import Foundation

// MARK: - Login Response with 2FA Support
struct LoginWith2FAResponse: Codable {
    let requiresTwoFactor: Bool
    let requires2FASetup: Bool? // NEW: First-time 2FA setup required
    let tempToken: String?
    let appToken: String?
    let email: String?
    let displayName: String?
    let role: String?
    let isActive: Bool
}

// MARK: - 2FA Verification Request
struct Verify2FARequest: Codable {
    let email: String
    let code: String
    let tempToken: String
}

// MARK: - Enable 2FA Request
struct Enable2FARequest: Codable {
    let password: String
}

// MARK: - Enable 2FA Response
struct Enable2FAResponse: Codable {
    let secret: String
    let qrCodeUri: String
    let backupCodes: [String]
}

// MARK: - Verify 2FA Setup Request
struct Verify2FASetupRequest: Codable {
    let code: String
}

// MARK: - Generic Message Response
struct MessageResponse: Codable {
    let message: String
}
