//
//  ForgotPasswordView.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 1/2/26.
//  Created for Password Reset
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var loading = false
    @State private var statusMessage: String?
    @State private var showResetTokenAlert = false
    @State private var resetToken = ""
    @State private var showResetForm = false
    
    var body: some View {
        NavigationView {
            ZStack {
                RamaTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 60))
                                .foregroundColor(RamaTheme.primary)
                            
                            Text("Forgot Password?")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(RamaTheme.primary)
                            
                            Text("Enter your email address and we'll send you instructions to reset your password.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 32)
                        
                        // Form
                        VStack(spacing: 16) {
                            TextField("Email", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding(.horizontal, 32)
                            
                            Button {
                                handleForgotPassword()
                            } label: {
                                if loading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Send Reset Link")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding()
                            .background(canSubmit ? RamaTheme.primary : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .disabled(!canSubmit || loading)
                            .padding(.horizontal, 32)
                        }
                        
                        // Status Message
                        if let status = statusMessage {
                            Text(status)
                                .font(.caption)
                                .foregroundColor(status.contains("success") || status.contains("sent") ? .green : .red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        Spacer()
                        
                        // Back to Login
                        Button {
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text("Back to Login")
                            }
                            .font(.subheadline)
                            .foregroundColor(RamaTheme.primary)
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Reset Token (Development)", isPresented: $showResetTokenAlert) {
                Button("Copy Token") {
                    UIPasteboard.general.string = resetToken
                }
                Button("Enter Token") {
                    showResetForm = true
                }
                Button("OK") { }
            } message: {
                Text("Token: \(resetToken)\n\nThis is only shown in development mode.")
            }
            .sheet(isPresented: $showResetForm) {
                ResetPasswordView(resetToken: resetToken)
            }
        }
    }
    
    var canSubmit: Bool {
        !email.isEmpty && email.contains("@")
    }
    
    func handleForgotPassword() {
        loading = true
        statusMessage = nil
        
        Task {
            do {
                let response = try await AuthAPI.shared.forgotPassword(email: email)
                
                await MainActor.run {
                    statusMessage = response.message
                    
                    // In development mode, show the token
                    if let token = response.resetToken {
                        resetToken = token
                        showResetTokenAlert = true
                    }
                    
                    loading = false
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

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
