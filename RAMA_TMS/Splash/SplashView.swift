//
// SplashView.swift
// RAMA_TMS
//
// Created by Tejasvi Mahesh on 12/21/25.
// Updated with Offline Mode Support
//

import SwiftUI

struct SplashView: View {
    let onHealthCheckPassed: () -> Void
    
    @State private var healthCheckFailed = false
    @State private var errorMessage = ""
    @State private var isRetrying = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.5
    @StateObject private var offlineManager = OfflineManager.shared
    @State private var hasOfflineCredentials = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.95, blue: 0.9),
                    Color(red: 1.0, green: 0.88, blue: 0.7)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Logo
                Image("rama-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                // App Name
                Text("Ananthaadi Rayara Matha (RAMA) Atlanta, GA")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(RamaTheme.primary)
                    .opacity(opacity)
                
                Text("RAMA Donations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .opacity(opacity)
                
                Spacer()
                
                // Health Check Status
                if !healthCheckFailed {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: RamaTheme.primary))
                            .scaleEffect(1.2)
                        
                        Text(isRetrying ? "Retrying connection..." : "Connecting to server...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Error State with Offline Option
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Connection Failed")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        // Offline Mode Availability Notice
                        if hasOfflineCredentials {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Offline mode available")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(20)
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            // Retry Connection Button
                            Button {
                                retryConnection()
                            } label: {
                                HStack {
                                    if isRetrying {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                    Text("Retry Connection")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(RamaTheme.primary)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isRetrying)
                            .padding(.horizontal, 32)
                            
                            // Continue Offline Button (NEW)
                            Button {
                                continueOffline()
                            } label: {
                                HStack {
                                    Image(systemName: "wifi.slash")
                                    Text("Continue Offline")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(hasOfflineCredentials ? RamaTheme.primary : Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 32)
                            
                            // Check Network Settings Button
                            Button {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "wifi")
                                    Text("Check Network Settings")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(RamaTheme.primary)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(RamaTheme.primary, lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                }
                
                Spacer()
                
                // Network Status Indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(offlineManager.isOnline ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(offlineManager.isOnline ? "Online" : "Offline")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .opacity(opacity)
                
                // Version
                Text("Version 1.0.0")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .opacity(opacity)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            checkOfflineAvailability()
            performHealthCheck()
            animateLogo()
        }
    }
    
    func animateLogo() {
        withAnimation(.easeOut(duration: 0.8)) {
            scale = 1.0
            opacity = 1.0
        }
    }
    
    func checkOfflineAvailability() {
        hasOfflineCredentials = OfflineAuthManager.shared.isOfflineLoginAvailable()
        if hasOfflineCredentials {
            print("✅ Offline login available for: \(OfflineAuthManager.shared.getCachedEmail() ?? "unknown")")
        }
    }
    
    func performHealthCheck() {
        Task {
            // Add small delay for UX
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            let status = try await AuthAPI.shared.checkHealth()
            
            await MainActor.run {
                handleHealthStatus(status)
            }
        }
    }
    
    func handleHealthStatus(_ status: HealthStatus) {
        switch status {
        case .healthy:
            // Health check passed - trigger callback to switch to main
            onHealthCheckPassed()
            
        case .unhealthy(let message):
            healthCheckFailed = true
            errorMessage = """
            The server is experiencing issues.
            
            \(message)
            
            Please try again in a few moments or contact support if the problem persists.
            """
            
        case .networkError:
            healthCheckFailed = true
            errorMessage = """
            Unable to connect to the server.
            
            Please check your internet connection and try again.
            
            \(hasOfflineCredentials ? "You can continue working offline with cached credentials." : "")
            """
            
        case .timeout:
            healthCheckFailed = true
            errorMessage = """
            Connection timeout.
            
            The server is taking too long to respond. This could be due to:
            • Slow internet connection
            • Server maintenance
            
            \(hasOfflineCredentials ? "You can continue working offline." : "Please check your connection and try again.")
            """
        }
    }
    
    func retryConnection() {
        isRetrying = true
        healthCheckFailed = false
        errorMessage = ""
        
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            
            let status = try await AuthAPI.shared.checkHealth()
            
            await MainActor.run {
                isRetrying = false
                handleHealthStatus(status)
            }
        }
    }
    
    // NEW: Continue Offline Function
    func continueOffline() {
        print("🔄 User chose to continue offline")
        
        // Proceed to main app even though health check failed
        // The offline indicator will show throughout the app
        onHealthCheckPassed()
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(onHealthCheckPassed: {})
    }
}
