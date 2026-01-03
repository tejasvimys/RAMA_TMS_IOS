//
//  OfflineAuthManager.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 1/2/26.
//  Offline Authentication with 2FA Support
//

import Foundation
import CryptoKit

class OfflineAuthManager {
    static let shared = OfflineAuthManager()
    
    private init() {}
    
    // MARK: - Cache Credentials After Successful Online Login
    
    func cacheCredentialsAfterLogin(
        email: String,
        password: String,
        displayName: String,
        role: String,
        userId: String,
        twoFactorEnabled: Bool,
        twoFactorSecret: String?
    ) {
        // Hash the password for storage
        let passwordHash = hashPassword(password)
        
        // Save to keychain
        let success = SecureStorage.shared.cacheUserCredentials(
            email: email,
            passwordHash: passwordHash,
            displayName: displayName,
            role: role,
            userId: userId,
            twoFactorEnabled: twoFactorEnabled,
            twoFactorSecret: twoFactorSecret
        )
        
        if success {
            print("✅ User credentials cached for offline access")
        }
    }
    
    // MARK: - Offline Login Verification
    
    func verifyOfflineLogin(email: String, password: String) -> (success: Bool, displayName: String?, role: String?, userId: String?, requires2FA: Bool, error: String?) {
        // Check if we have cached credentials
        guard let cached = SecureStorage.shared.getCachedCredentials() else {
            return (false, nil, nil, nil, false, "No cached credentials found. Please login online first.")
        }
        
        // Verify email matches
        guard email.lowercased() == cached.email.lowercased() else {
            return (false, nil, nil, nil, false, "Email does not match cached credentials.")
        }
        
        // Verify password
        let passwordHash = hashPassword(password)
        guard passwordHash == cached.passwordHash else {
            return (false, nil, nil, nil, false, "Invalid password.")
        }
        
        print("✅ Offline password verified")
        
        // Check if 2FA is required
        if cached.twoFactorEnabled {
            return (true, cached.displayName, cached.role, cached.userId, true, nil)
        }
        
        // No 2FA required - login successful
        return (true, cached.displayName, cached.role, cached.userId, false, nil)
    }
    
    // MARK: - Offline 2FA Verification
    
    func verifyOffline2FA(code: String) -> (success: Bool, error: String?) {
        guard let cached = SecureStorage.shared.getCachedCredentials() else {
            return (false, "No cached credentials found.")
        }
        
        guard cached.twoFactorEnabled else {
            return (false, "2FA is not enabled for this account.")
        }
        
        guard let secret = cached.twoFactorSecret else {
            return (false, "2FA secret not found. Please login online.")
        }
        
        // Validate TOTP code using TOTPHelper (FIXED)
        let isValid = TOTPHelper.validateCode(secret, code)
        
        if isValid {
            print("✅ Offline 2FA verified")
            return (true, nil)
        } else {
            print("❌ Offline 2FA failed")
            return (false, "Invalid 2FA code.")
        }
    }
    
    // MARK: - Check if Offline Login is Available
    
    func isOfflineLoginAvailable() -> Bool {
        return SecureStorage.shared.getCachedCredentials() != nil
    }
    
    func getCachedEmail() -> String? {
        return SecureStorage.shared.getCachedCredentials()?.email
    }
    
    // MARK: - Clear Cached Credentials (Logout)
    
    func clearCache() {
        SecureStorage.shared.clearCachedCredentials()
    }
    
    // MARK: - Password Hashing
    
    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Update Cached 2FA Secret (when enabled/disabled)
    
    func updateCached2FASecret(secret: String?, enabled: Bool) {
        guard var cached = SecureStorage.shared.getCachedCredentials() else { return }
        
        let _ = SecureStorage.shared.cacheUserCredentials(
            email: cached.email,
            passwordHash: cached.passwordHash,
            displayName: cached.displayName,
            role: cached.role,
            userId: cached.userId,
            twoFactorEnabled: enabled,
            twoFactorSecret: secret
        )
        
        print("✅ Cached 2FA settings updated")
    }
}
