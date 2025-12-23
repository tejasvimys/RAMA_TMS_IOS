//
//  LoginView.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/22/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    
    @State private var mode: AuthMode = .google
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isRegister = false
    @State private var loading = false
    @State private var statusMessage: String?
    
    enum AuthMode {
        case google, email
    }
    
    var body: some View {
        ZStack {
            RamaTheme.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image("rama-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                
                Text("Ananthaadi Rayara Matha")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(RamaTheme.primary)
                
                // Mode tabs
                Picker("Auth Mode", selection: $mode) {
                    Text("Google").tag(AuthMode.google)
                    Text("Email").tag(AuthMode.email)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 32)
                
                if mode == .google {
                    googleSignInSection
                } else {
                    emailSignInSection
                }
                
                if let status = statusMessage {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .padding()
        }
    }
    
    var googleSignInSection: some View {
        VStack(spacing: 16) {
            Text("Sign in with your Google account")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button {
                handleGoogleSignIn()
            } label: {
                Text("Sign in with Google")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RamaTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            
            Text("(Google Sign-In SDK integration required)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    var emailSignInSection: some View {
        VStack(spacing: 12) {
            if isRegister {
                TextField("Name", text: $displayName)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.words)
            }
            
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
            
            Button {
                handleEmailAuth()
            } label: {
                if loading {
                    ProgressView()
                } else {
                    Text(isRegister ? "Register" : "Login")
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(canSubmit ? RamaTheme.primary : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(!canSubmit || loading)
            
            Button {
                isRegister.toggle()
                statusMessage = nil
            } label: {
                Text(isRegister ? "Already have an account? Login" : "New here? Register")
                    .font(.caption)
                    .foregroundColor(RamaTheme.primary)
            }
        }
        .padding(.horizontal, 32)
    }
    
    var canSubmit: Bool {
        !email.isEmpty && password.count >= 6
    }
    
    func handleGoogleSignIn() {
        // TODO: Integrate Google Sign-In SDK
        // On success, get idToken and call:
        // let response = try await AuthAPI.shared.exchangeGoogleToken(idToken)
        // auth.handleAuthResponse(response)
        
        statusMessage = "Google Sign-In not yet integrated. Use Email login for now."
    }
    
    func handleEmailAuth() {
        loading = true
        statusMessage = nil
        
        Task {
            do {
                if isRegister {
                    let message = try await AuthAPI.shared.register(
                        email: email,
                        displayName: displayName.isEmpty ? email : displayName,
                        password: password
                    )
                    await MainActor.run {
                        statusMessage = message
                        isRegister = false
                        password = ""
                        loading = false
                    }
                } else {
                    let response = try await AuthAPI.shared.login(email: email, password: password)
                    await MainActor.run {
                        if response.isActive, response.appToken != nil {
                            auth.handleAuthResponse(response)
                        } else {
                            statusMessage = "Account pending admin approval."
                        }
                        loading = false
                    }
                }
            } catch {
                await MainActor.run {
                    statusMessage = error.localizedDescription
                    loading = false
                }
            }
        }
    }
}
