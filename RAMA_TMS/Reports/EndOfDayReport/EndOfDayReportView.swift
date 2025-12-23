//
//  EndOfDayReportView.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/23/25.
//

import SwiftUI

struct EndOfDayReportView: View {
    @State private var reportData: EndOfDayReport?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isSendingEmail = false
    @State private var sendSuccess = false
    @State private var selectedDate = Date()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var auth: AuthViewModel
    
    var body: some View {
        ZStack {
            RamaTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    ReportHeaderView()
                    
                    // Debug Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Debug Info")
                            .font(.caption)
                            .fontWeight(.bold)
                        
                        if let token = UserDefaults.standard.string(forKey: "appToken") { // Changed from "authToken"
                            Text("Token: \(token.prefix(30))...")
                                .font(.caption2)
                                .foregroundColor(.green)
                        } else {
                            Text("No token found")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                        
                        Text("User: \(auth.displayName)")
                            .font(.caption2)
                        Text("Role: \(auth.role ?? "N/A")")
                            .font(.caption2)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    DatePickerCard(selectedDate: $selectedDate, onDateChange: loadReport)
                    
                    if isLoading {
                        LoadingView()
                    } else if let error = errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            HStack(spacing: 12) {
                                Button("Retry") {
                                    loadReport()
                                }
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(RamaTheme.primary)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                
                                Button("View Logs") {
                                    printDebugInfo()
                                }
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(RamaTheme.card)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    } else if let report = reportData {
                        ReportContentView(report: report)
                        ReportActionsView(
                            isSendingEmail: $isSendingEmail,
                            sendSuccess: $sendSuccess,
                            onSendEmail: sendEmailReport,
                            hasReport: true
                        )
                    } else {
                        EmptyReportView()
                    }
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("End of Day Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .onAppear(perform: loadReport)
    }
    
    // MARK: - Functions
    
    private func loadReport() {
        isLoading = true
        errorMessage = nil
        sendSuccess = false
        reportData = nil
        
        print("🔄 Loading report for date: \(selectedDate)")
        
        Task {
            do {
                let report = try await EndOfDayAPI.shared.getReport(for: selectedDate)
                await MainActor.run {
                    self.reportData = report
                    self.isLoading = false
                    print("✅ Report loaded successfully")
                }
            } catch {
                await MainActor.run {
                    // NO AUTH POPUP - Just show error message
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    self.reportData = nil
                    print("❌ Error loading report: \(error)")
                }
            }
        }
    }
    
    private func sendEmailReport() {
        guard reportData != nil else { return }
        
        isSendingEmail = true
        sendSuccess = false
        errorMessage = nil
        
        Task {
            do {
                try await EndOfDayAPI.shared.sendReportEmail(date: selectedDate)
                await MainActor.run {
                    self.isSendingEmail = false
                    self.sendSuccess = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation {
                            self.sendSuccess = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isSendingEmail = false
                    self.errorMessage = "Failed to send email: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func printDebugInfo() {
        print("\n" + String(repeating: "=", count: 60))
        print("🔍 DEBUG INFORMATION")
        print(String(repeating: "=", count: 60))
        
        // Check token
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            print("✅ Token exists")
            print("   Length: \(token.count)")
            print("   Prefix: \(token.prefix(50))...")
        } else {
            print("❌ No token found in UserDefaults")
        }
        
        // Check user info
        print("\n👤 User Info:")
        print("   Name: \(auth.displayName)")
        print("   Email: \(auth.email ?? "N/A")")
        print("   Role: \(auth.role ?? "N/A")")
        
        // Check selected date
        print("\n📅 Selected Date:")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        print("   Formatted: \(formatter.string(from: selectedDate))")
        
        // Try to construct the URL
        let dateString = formatter.string(from: selectedDate)
        let baseURL = "YOUR_BASE_URL" // Replace with actual
        let fullURL = "\(baseURL)/api/reports/end-of-day?date=\(dateString)"
        print("\n🌐 Request URL:")
        print("   \(fullURL)")
        
        print("\n" + String(repeating: "=", count: 60) + "\n")
    }
}

#Preview {
    NavigationView {
        EndOfDayReportView()
            .environmentObject(AuthViewModel())
    }
}

