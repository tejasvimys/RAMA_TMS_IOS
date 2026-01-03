//
//  ContentView.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/18/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth: AuthViewModel
    
    var body: some View {
        Group {
            if auth.isAuthenticated {
                // User is authenticated - show HomeView
                HomeView()
            } else {
                // User is not authenticated - show LoginView
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
