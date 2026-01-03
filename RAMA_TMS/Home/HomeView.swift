//
//  HomeView.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/21/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var auth: AuthViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Light gradient background
                LinearGradient(
                    colors: [Color(red: 0.98, green: 0.96, blue: 0.92), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Welcome card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome back,")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(auth.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.9, green: 0.49, blue: 0))
                            
                            if let role = auth.role {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.caption)
                                    Text(role)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.green)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal)
                        
                        // Action tiles
                        VStack(spacing: 16) {
                            Text("Quick Actions")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            
                            // First row - Add Donation & My Donations
                            HStack(spacing: 16) {
                                NavigationLink {
                                    AddDonationView()
                                } label: {
                                    ActionTile(
                                        title: "Add Donation",
                                        subtitle: "Record new donation",
                                        icon: "plus.circle.fill",
                                        color: Color(red: 0.9, green: 0.49, blue: 0)
                                    )
                                }
                                
                                NavigationLink {
                                    DonationsListView()
                                } label: {
                                    ActionTile(
                                        title: "My Donations",
                                        subtitle: "View collection",
                                        icon: "list.bullet.rectangle.fill",
                                        color: Color(red: 0.2, green: 0.6, blue: 0.86)
                                    )
                                }
                            }
                            .padding(.horizontal)
                            
                            // Second row - End of Day Report
                            HStack(spacing: 16) {
                                NavigationLink {
                                    EndOfDayReportView()
                                } label: {
                                    ActionTile(
                                        title: "EOD Report",
                                        subtitle: "Daily summary",
                                        icon: "doc.text.fill",
                                        color: Color(red: 0.4, green: 0.49, blue: 0.92)
                                    )
                                }
                                
                                // Placeholder for future feature or empty space
                                ActionTile(
                                    title: "Coming Soon",
                                    subtitle: "New feature",
                                    icon: "sparkles",
                                    color: Color.gray.opacity(0.5)
                                )
                                .opacity(0.6)
                            }
                            
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        auth.logout()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Logout")
                                .font(.subheadline)
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
