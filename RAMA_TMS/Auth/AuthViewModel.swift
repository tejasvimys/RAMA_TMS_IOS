//
//  AuthViewModel.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/21/25.
//  Updated with Offline Authentication Support
//

import Foundation

final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var role: String? = nil
    @Published var token: String? = nil
    @Published var isOfflineMode = false
    
    private let offlineManager = OfflineManager.shared
    
    init() {
        // Load saved session
        loadSavedSession()
    }
    
    // MARK: - Load Saved Session
    
    private func loadSavedSession() {
        if let saved = UserDefaults.standard.string(forKey: "appToken"),
           let savedEmail = UserDefaults.standard.string(forKey: "userEmail"),
           let savedName = UserDefaults.standard.string(forKey: "userName"),
           let savedRole = UserDefaults.standard.string(forKey: "userRole") {
            self.token = saved
            self.email = savedEmail
            self.displayName = savedName
            self.role = savedRole
            self.isAuthenticated = true
            self.isOfflineMode = false
            
            print("✅ Session restored from UserDefaults")
        }
    }
    
    // MARK: - Online Authentication (Server Response)
    
    func handleAuthResponse(_ response: TokenExchangeResponse) {
        guard response.isActive, let appToken = response.appToken else {
            return
        }
        
        self.token = appToken
        self.email = response.email
        self.displayName = response.displayName
        self.role = response.role
        self.isAuthenticated = true
        self.isOfflineMode = false
        
        // Persist to UserDefaults
        UserDefaults.standard.set(appToken, forKey: "appToken")
        UserDefaults.standard.set(response.email, forKey: "userEmail")
        UserDefaults.standard.set(response.displayName, forKey: "userName")
        UserDefaults.standard.set(response.role, forKey: "userRole")
        
        print("✅ Online authentication successful")
    }
    
    // MARK: - Offline Authentication (Cached Credentials)
    
    func handleOfflineAuth(email: String, displayName: String, role: String, userId: String) {
        self.token = "OFFLINE_TOKEN_\(userId)" // Dummy token for offline mode
        self.email = email
        self.displayName = displayName
        self.role = role
        self.isAuthenticated = true
        self.isOfflineMode = true
        
        // Persist to UserDefaults
        UserDefaults.standard.set(self.token, forKey: "appToken")
        UserDefaults.standard.set(email, forKey: "userEmail")
        UserDefaults.standard.set(displayName, forKey: "userName")
        UserDefaults.standard.set(role, forKey: "userRole")
        
        print("✅ Offline authentication successful")
    }
    
    // MARK: - Cache Credentials After Online Login
    
    func cacheCredentialsForOffline(
        password: String,
        userId: String,
        twoFactorEnabled: Bool,
        twoFactorSecret: String?
    ) {
        OfflineAuthManager.shared.cacheCredentialsAfterLogin(
            email: email,
            password: password,
            displayName: displayName,
            role: role ?? "Collector",
            userId: userId,
            twoFactorEnabled: twoFactorEnabled,
            twoFactorSecret: twoFactorSecret
        )
    }
    
    // MARK: - Logout
    
    func logout() {
        isAuthenticated = false
        token = nil
        email = ""
        displayName = ""
        role = nil
        isOfflineMode = false
        
        UserDefaults.standard.removeObject(forKey: "appToken")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userRole")
        
        print("👋 Logged out")
    }
    
    // MARK: - Full Logout (Clear Cache)
    
    func logoutAndClearCache() {
        logout()
        OfflineAuthManager.shared.clearCache()
        print("🗑️ Logged out and cleared cached credentials")
    }
    
    // MARK: - Check Offline Availability
    
    func isOfflineLoginAvailable() -> Bool {
        return OfflineAuthManager.shared.isOfflineLoginAvailable()
    }
}
