//
//  ResetPasswordView.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 1/2/26.
//  Created for Password Reset
//

import SwiftUI

struct ResetPasswordView: View {
    @Environment(\.dismiss) var dismiss
    
    let resetToken: String
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var loading = false
    @State private var statusMessage: String?
    @State private var tokenValidated = false
    @State private var userEmail = ""
    @State private var passwordResetSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                RamaTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: passwordResetSuccess ? "checkmark.circle.fill" : "lock.rotation")
                                .font(.system(size: 60))
                                .foregroundColor(passwordResetSuccess ? .green : RamaTheme.primary)
                            
                            Text(passwordResetSuccess ? "Password Reset!" : "Reset Password")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(passwordResetSuccess ? .green : RamaTheme.primary)
                            
                            if tokenValidated && !passwordResetSuccess {
                                Text("Enter a new password for \(userEmail)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            
                            if passwordResetSuccess {
                                Text("Your password has been reset successfully. You can now login with your new password.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top, 32)
                        
                        if !passwordResetSuccess {
                            // Form
                            VStack(spacing: 16) {
                                SecureField("New Password", text: $newPassword)
                                    .textFieldStyle(.roundedBorder)
                                    .padding(.horizontal, 32)
                                
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textFieldStyle(.roundedBorder)
                                    .padding(.horizontal, 32)
                                
                                // Password requirements
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Password must:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: newPassword.count >= 6 ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(newPassword.count >= 6 ? .green : .gray)
                                            .font(.caption)
                                        Text("Be at least 6 characters")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(passwordsMatch ? .green : .gray)
                                            .font(.caption)
                                        Text("Passwords match")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 32)
                                
                                Button {
                                    handleResetPassword()
                                } label: {
                                    if loading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Reset Password")
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
                        } else {
                            // Success - Show login button
                            Button {
                                dismiss()
                            } label: {
                                Text("Go to Login")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(RamaTheme.primary)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 32)
                        }
                        
                        // Status Message
                        if let status = statusMessage {
                            Text(status)
                                .font(.caption)
                                .foregroundColor(status.contains("success") ? .green : .red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        Spacer()
                        
                        // Cancel button
                        if !passwordResetSuccess {
                            Button {
                                dismiss()
                            } label: {
                                Text("Cancel")
                                    .font(.subheadline)
                                    .foregroundColor(RamaTheme.primary)
                            }
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                validateToken()
            }
        }
    }
    
    var canSubmit: Bool {
        newPassword.count >= 6 && passwordsMatch && tokenValidated
    }
    
    var passwordsMatch: Bool {
        !confirmPassword.isEmpty && newPassword == confirmPassword
    }
    
    func validateToken() {
        loading = true
        
        Task {
            do {
                let response = try await AuthAPI.shared.validateResetToken(token: resetToken)
                
                await MainActor.run {
                    userEmail = response.email
                    tokenValidated = true
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
    
    func handleResetPassword() {
        loading = true
        statusMessage = nil
        
        Task {
            do {
                let message = try await AuthAPI.shared.resetPassword(
                    token: resetToken,
                    newPassword: newPassword
                )
                
                await MainActor.run {
                    statusMessage = message
                    passwordResetSuccess = true
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

struct ResetPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ResetPasswordView(resetToken: "sample-token")
    }
}
