//
//  DonationDetailView.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 1/4/26.
//
//  Shows detailed information about a donation with PDF viewing option
//

import SwiftUI

struct DonationDetailView: View {
    let donation: OfflineDonation
    
    @State private var showPDFViewer = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Amount card at the top
                amountCard
                
                // Donor information section
                SectionCard(title: "Donor Information", icon: "person.fill") {
                    VStack(spacing: 12) {
                        DetailRow(label: "Name", value: donation.donorDisplayName)
                        
                        if let email = donation.donorEmail, !email.isEmpty {
                            DetailRow(label: "Email", value: email)
                        }
                        
                        if let phone = donation.donorPhone, !phone.isEmpty {
                            DetailRow(label: "Phone", value: phone)
                        }
                        
                        if donation.hasAddress {
                            DetailRow(label: "Address", value: donation.fullAddress)
                        }
                    }
                }
                
                // Donation details section
                SectionCard(title: "Donation Details", icon: "dollarsign.circle.fill") {
                    VStack(spacing: 12) {
                        DetailRow(label: "Type", value: donation.donationType)
                        DetailRow(label: "Date", value: donation.formattedDate)
                        DetailRow(label: "Payment", value: donation.paymentInfo)
                        
                        if let notes = donation.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(notes)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                
                // Receipt section with PDF viewing
                SectionCard(title: "Receipt", icon: "doc.text.fill") {
                    VStack(spacing: 12) {
                        DetailRow(label: "Receipt Number", value: donation.receiptNumber)
                        
                        HStack {
                            Text("Status")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            StatusBadge(status: donation.syncStatus)
                        }
                        
                        // View PDF button (only if synced and has server ID)
                        if donation.syncStatus == "synced" && donation.serverDonationId > 0 {
                            Button(action: { showPDFViewer = true }) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                    Text("View PDF Receipt")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(RamaTheme.primary)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.top, 8)
                        } else if donation.syncStatus == "pending" || donation.syncStatus == "syncing" {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.orange)
                                Text("Receipt will be available after sync")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 8)
                        } else if donation.syncStatus == "failed" || donation.syncStatus == "failed_permanent" {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("Sync failed. PDF not available.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(RamaTheme.background)
        .navigationTitle("Donation Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPDFViewer) {
            NavigationView {
                PDFViewerView(
                    receiptId: donation.serverDonationId,
                    donorName: donation.donorName
                )
            }
        }
    }
    
    // MARK: - Amount Card
    private var amountCard: some View {
        VStack(spacing: 8) {
            Text(donation.formattedAmount)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(RamaTheme.primary)
            
            Text(donation.donationType)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(RamaTheme.card)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Detail Row Component
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Status Badge Component
struct StatusBadge: View {
    let status: String
    
    var statusColor: Color {
        switch status {
        case "synced": return .green
        case "pending": return .orange
        case "syncing": return .blue
        case "failed", "failed_permanent": return .red
        default: return .gray
        }
    }
    
    var statusText: String {
        switch status {
        case "pending": return "Pending Sync"
        case "syncing": return "Syncing..."
        case "synced": return "Synced"
        case "failed": return "Failed"
        case "failed_permanent": return "Failed (Permanent)"
        default: return status.capitalized
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct DonationDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DonationDetailView(donation: createSampleDonation())
        }
    }
    
    static func createSampleDonation() -> OfflineDonation {
        let context = PersistenceController.preview.container.viewContext
        let donation = OfflineDonation(context: context)
        donation.id = UUID()
        donation.donorName = "John Doe"
        donation.donorEmail = "john@example.com"
        donation.amount = NSDecimalNumber(value: 100.0)
        donation.donationType = "General"
        donation.receiptNumber = "OFF-12345"
        donation.createdAt = Date()
        donation.syncStatus = "synced"
        donation.serverDonationId = 123
        return donation
    }
}
