//
//  AuthViewModel.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/21/25.
//

import Foundation

final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var role: String? = nil
    @Published var token: String? = nil
    
    init() {
        // Load saved session
        if let saved = UserDefaults.standard.string(forKey: "appToken"),
           let savedEmail = UserDefaults.standard.string(forKey: "userEmail"),
           let savedName = UserDefaults.standard.string(forKey: "userName"),
           let savedRole = UserDefaults.standard.string(forKey: "userRole") {
            self.token = saved
            self.email = savedEmail
            self.displayName = savedName
            self.role = savedRole
            self.isAuthenticated = true
        }
    }
    
    func handleAuthResponse(_ response: TokenExchangeResponse) {
        guard response.isActive, let appToken = response.appToken else {
            // Not approved yet
            return
        }
        
        self.token = appToken
        self.email = response.email
        self.displayName = response.displayName
        self.role = response.role
        self.isAuthenticated = true
        
        // Persist
        UserDefaults.standard.set(appToken, forKey: "appToken")
        UserDefaults.standard.set(response.email, forKey: "userEmail")
        UserDefaults.standard.set(response.displayName, forKey: "userName")
        UserDefaults.standard.set(response.role, forKey: "userRole")
    }
    
    func logout() {
        isAuthenticated = false
        token = nil
        email = ""
        displayName = ""
        role = nil
        
        UserDefaults.standard.removeObject(forKey: "appToken")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userRole")
    }
}
