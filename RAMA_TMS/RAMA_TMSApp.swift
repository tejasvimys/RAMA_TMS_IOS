//
//  RAMA_TMSApp.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/18/25.
//

import SwiftUI

enum AppRoute {
    case splash
    case main  // After health check passes
}

@main
struct RamaApp: App {
    @StateObject private var auth = AuthViewModel()
    @State private var route: AppRoute = .splash
    
    init() {
        // TEMPORARY: Clear saved session for testing
        // Uncomment if you want to clear session on app launch
//        UserDefaults.standard.removeObject(forKey: "appToken")
//        UserDefaults.standard.removeObject(forKey: "userEmail")
//        UserDefaults.standard.removeObject(forKey: "userName")
//        UserDefaults.standard.removeObject(forKey: "userRole")
        
        let _ = PersistenceController.shared
        print("✅ Core Data initialized")
        
        // Initialize offline manager
            let _ = OfflineManager.shared
            
            // Test: Print stats on launch
            let stats = PersistenceController.shared.getStats()
            print("📊 Offline Stats - Donations: \(stats.donations), Pending Sync: \(stats.pendingSync)")
        
        // Test offline auth availability
        if OfflineAuthManager.shared.isOfflineLoginAvailable() {
            print("✅ Offline login available for: \(OfflineAuthManager.shared.getCachedEmail() ?? "unknown")")
        } else {
            print("ℹ️ No cached credentials - offline login not available")
        }
        
        // Test TOTP generation
        let testSecret = "JBSWY3DPEHPK3PXP" // RFC test vector
        if let code = TOTPHelper.generateCurrentCode(secret: testSecret) {
            print("✅ TOTP Code generated: \(code)")
            
            // Verify the code
            let isValid = TOTPHelper.validateCode(testSecret, code)
            print(isValid ? "✅ TOTP validation passed" : "❌ TOTP validation failed")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch route {
                case .splash:
                    SplashView(onHealthCheckPassed: {
                        route = .main
                    })
                    
                case .main:
                    ContentView()
                        .environmentObject(auth)
                }
            }
        }
    }
}
