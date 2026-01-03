//
//  SecureStorage.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 1/2/26.
//  Secure Keychain Storage for Offline Authentication
//

import Foundation
import Security

class SecureStorage {
    static let shared = SecureStorage()
    
    private init() {}
    
    // MARK: - Save to Keychain
    
    func save(key: String, data: Data) -> Bool {
        // Delete old item first
        delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return save(key: key, data: data)
    }
    
    // MARK: - Load from Keychain
    
    func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    func loadString(key: String) -> String? {
        guard let data = load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Delete from Keychain
    
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Clear All
    
    func clearAll() {
        let secItemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]
        
        for itemClass in secItemClasses {
            let spec: [String: Any] = [kSecClass as String: itemClass]
            SecItemDelete(spec as CFDictionary)
        }
    }
}

// MARK: - Keys for Cached Authentication

extension SecureStorage {
    // Key names for cached auth data
    static let cachedEmailKey = "com.ramatms.cached.email"
    static let cachedPasswordHashKey = "com.ramatms.cached.passwordHash"
    static let cached2FASecretKey = "com.ramatms.cached.2faSecret"
    static let cached2FAEnabledKey = "com.ramatms.cached.2faEnabled"
    static let cachedDisplayNameKey = "com.ramatms.cached.displayName"
    static let cachedRoleKey = "com.ramatms.cached.role"
    static let cachedUserIdKey = "com.ramatms.cached.userId"
    
    // Save user credentials for offline auth
    func cacheUserCredentials(
        email: String,
        passwordHash: String,
        displayName: String,
        role: String,
        userId: String,
        twoFactorEnabled: Bool,
        twoFactorSecret: String?
    ) -> Bool {
        var success = true
        
        success = success && save(key: Self.cachedEmailKey, value: email)
        success = success && save(key: Self.cachedPasswordHashKey, value: passwordHash)
        success = success && save(key: Self.cachedDisplayNameKey, value: displayName)
        success = success && save(key: Self.cachedRoleKey, value: role)
        success = success && save(key: Self.cachedUserIdKey, value: userId)
        success = success && save(key: Self.cached2FAEnabledKey, value: twoFactorEnabled ? "true" : "false")
        
        if let secret = twoFactorSecret {
            success = success && save(key: Self.cached2FASecretKey, value: secret)
        }
        
        print(success ? "✅ Credentials cached for offline login" : "❌ Failed to cache credentials")
        return success
    }
    
    // Get cached credentials
    func getCachedCredentials() -> (email: String, passwordHash: String, displayName: String, role: String, userId: String, twoFactorEnabled: Bool, twoFactorSecret: String?)? {
        guard let email = loadString(key: Self.cachedEmailKey),
              let passwordHash = loadString(key: Self.cachedPasswordHashKey),
              let displayName = loadString(key: Self.cachedDisplayNameKey),
              let role = loadString(key: Self.cachedRoleKey),
              let userId = loadString(key: Self.cachedUserIdKey),
              let twoFactorEnabledStr = loadString(key: Self.cached2FAEnabledKey) else {
            return nil
        }
        
        let twoFactorEnabled = twoFactorEnabledStr == "true"
        let twoFactorSecret = loadString(key: Self.cached2FASecretKey)
        
        return (email, passwordHash, displayName, role, userId, twoFactorEnabled, twoFactorSecret)
    }
    
    // Clear cached credentials
    func clearCachedCredentials() {
        delete(key: Self.cachedEmailKey)
        delete(key: Self.cachedPasswordHashKey)
        delete(key: Self.cached2FASecretKey)
        delete(key: Self.cached2FAEnabledKey)
        delete(key: Self.cachedDisplayNameKey)
        delete(key: Self.cachedRoleKey)
        delete(key: Self.cachedUserIdKey)
        
        print("🗑️ Cached credentials cleared")
    }
}
