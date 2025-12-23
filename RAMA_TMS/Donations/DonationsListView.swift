//
//  DonationsListView.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/21/25.
//

import SwiftUI

struct DonationsListView: View {
    @State private var items: [MobileDonationListItem] = []
    @State private var loading = false
    @State private var errorMessage: String?
    
    var body: some View {
        List {
            if let err = errorMessage {
                Text(err).foregroundColor(.red)
            }
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.donorName)
                        .font(.headline)
                        .foregroundColor(RamaTheme.primary)
                    Text("\(item.donationType) - $\(item.donationAmt, specifier: "%.2f")")
                        .font(.subheadline)
                    Text(item.dateOfDonation.formatted(date: .abbreviated, time: .shortened))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("My Donations")
        .onAppear(perform: load)
    }
    
    func load() {
        loading = true
        errorMessage = nil
        Task {
            do {
                let res = try await QuickDonationApi.shared.getMyDonations()
                await MainActor.run {
                    items = res
                    loading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed: \(error.localizedDescription)"
                    loading = false
                }
            }
        }
    }
}
