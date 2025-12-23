//
//  RAMA_TMSApp.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/18/25.
//

import SwiftUI

enum AppRoute {
    case splash
    case auth   // will use later for OAuth
    case home
}

@main
struct RamaApp: App {
    @StateObject private var auth = AuthViewModel()
    @State private var route: AppRoute = .splash
    
    init() {
            // TEMPORARY: Clear saved session for testing
//             UserDefaults.standard.removeObject(forKey: "appToken")
//             UserDefaults.standard.removeObject(forKey: "userEmail")
//             UserDefaults.standard.removeObject(forKey: "userName")
//             UserDefaults.standard.removeObject(forKey: "userRole")
        }

    var body: some Scene {
        WindowGroup {
            Group {
                switch route {
                case .splash:
                    SplashView()
                case .auth:
                    LoginView()
                        .environmentObject(auth)
                case .home:
                    HomeView()
                        .environmentObject(auth)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                    route = auth.isAuthenticated ? .home : .auth
                }
            }
            .onChange(of: auth.isAuthenticated) { _, newValue in
                route = newValue ? .home : .auth
            }
        }
    }
}
