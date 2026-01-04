//
// DonationsListView.swift
// RAMA_TMS
//
// Created by Tejasvi Mahesh on 12/21/25.
// Updated with Offline Donations Support & Detail Navigation
//

import SwiftUI

struct DonationsListView: View {
    @StateObject private var offlineManager = OfflineManager.shared
    @State private var onlineDonations: [MobileDonationListItem] = []
    @State private var offlineDonations: [OfflineDonation] = []
    @State private var loading = false
    @State private var errorMessage: String?
    @State private var selectedFilter: DonationFilter = .all
    
    enum DonationFilter: String, CaseIterable {
        case all = "All"
        case online = "Online"
        case offline = "Offline"
        case pending = "Pending Sync"
    }
    
    var filteredOfflineDonations: [OfflineDonation] {
        switch selectedFilter {
        case .all, .offline:
            return offlineDonations
        case .pending:
            return offlineDonations.filter { $0.syncStatus != "synced" }
        case .online:
            return []
        }
    }
    
    var filteredOnlineDonations: [MobileDonationListItem] {
        switch selectedFilter {
        case .all, .online:
            return onlineDonations
        case .offline, .pending:
            return []
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(DonationFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Sync Status Banner
            if offlineManager.isSyncing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(offlineManager.currentSyncItem ?? "Syncing...")
                        .font(.caption)
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
            } else if offlineManager.pendingSyncCount > 0 {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    Text("\(offlineManager.pendingSyncCount) donation(s) pending sync")
                        .font(.caption)
                    Spacer()
                    if offlineManager.isOnline {
                        Button("Sync Now") {
                            offlineManager.forceSyncNow()
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(RamaTheme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
            }
            
            // Donations List
            List {
                if let err = errorMessage {
                    Text(err)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Offline Donations Section (✅ WITH NAVIGATION)
                if !filteredOfflineDonations.isEmpty {
                    Section {
                        ForEach(filteredOfflineDonations, id: \.id) { donation in
                            NavigationLink(destination: DonationDetailView(donation: donation)) {
                                OfflineDonationRow(donation: donation)
                            }
                        }
                    } header: {
                        if selectedFilter == .all {
                            Text("Offline Donations")
                        }
                    }
                }
                
                // Online Donations Section (✅ WITH NAVIGATION - if you want details for online too)
                if !filteredOnlineDonations.isEmpty {
                    Section {
                        ForEach(filteredOnlineDonations) { item in
                            OnlineDonationRow(item: item)
                            // Note: Online donations don't have OfflineDonation objects
                            // so they can't use DonationDetailView yet
                            // You can add a separate detail view for online donations if needed
                        }
                    } header: {
                        if selectedFilter == .all {
                            Text("Online Donations")
                        }
                    }
                }
                
                // Empty State
                if filteredOfflineDonations.isEmpty && filteredOnlineDonations.isEmpty && !loading {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No donations found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        if selectedFilter != .all {
                            Text("Try changing the filter")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                }
            }
            .refreshable {
                await loadDonations()
            }
        }
        .navigationTitle("My Donations")
        .onAppear {
            loadAllDonations()
        }
        .onReceive(NotificationCenter.default.publisher(for: .networkStatusChanged)) { _ in
            // Reload when network status changes
            loadAllDonations()
        }
    }
    
    func loadAllDonations() {
        loading = true
        errorMessage = nil
        
        // Load offline donations immediately
        offlineDonations = offlineManager.getAllDonations()
        
        // Try to load online donations
        Task {
            await loadDonations()
        }
    }
    
    func loadDonations() async {
        do {
            let res = try await QuickDonationApi.shared.getMyDonations()
            await MainActor.run {
                onlineDonations = res
                // Refresh offline donations
                offlineDonations = offlineManager.getAllDonations()
                loading = false
            }
        } catch {
            await MainActor.run {
                // Don't show error if we have offline donations
                if offlineDonations.isEmpty {
                    errorMessage = "Failed to load online donations: \(error.localizedDescription)"
                }
                loading = false
            }
        }
    }
}

// MARK: - Offline Donation Row

struct OfflineDonationRow: View {
    let donation: OfflineDonation
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(donation.donorName)
                        .font(.headline)
                        .foregroundColor(RamaTheme.primary)
                    
                    // Sync Status Badge
                    SyncStatusBadge(status: donation.syncStatus)
                }
                
                Text("\(donation.donationType) - \(donation.formattedAmount)")
                    .font(.subheadline)
                
                Text(donation.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                
                Text("Receipt: \(donation.receiptNumber)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Sync icon
            if donation.syncStatus == "synced" {
                Image(systemName: "checkmark.icloud.fill")
                    .foregroundColor(.green)
            } else if donation.syncStatus == "pending" {
                Image(systemName: "icloud.and.arrow.up")
                    .foregroundColor(.orange)
            } else if donation.syncStatus == "failed" {
                Image(systemName: "exclamationmark.icloud")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Sync Status Badge

struct SyncStatusBadge: View {
    let status: String
    
    var badgeColor: Color {
        switch status {
        case "synced": return .green
        case "pending", "syncing": return .orange
        case "failed", "failed_permanent": return .red
        default: return .gray
        }
    }
    
    var statusText: String {
        switch status {
        case "synced": return "Synced"
        case "pending": return "Pending"
        case "syncing": return "Syncing"
        case "failed": return "Failed"
        case "failed_permanent": return "Failed"
        default: return status
        }
    }
    
    var body: some View {
        Text(statusText)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.2))
            .foregroundColor(badgeColor)
            .cornerRadius(4)
    }
}

// MARK: - Online Donation Row

struct OnlineDonationRow: View {
    let item: MobileDonationListItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.donorName)
                        .font(.headline)
                        .foregroundColor(RamaTheme.primary)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                Text("\(item.donationType) - $\(item.donationAmt, specifier: "%.2f")")
                    .font(.subheadline)
                
                Text(item.dateOfDonation.formatted(date: .abbreviated, time: .shortened))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "icloud.fill")
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

