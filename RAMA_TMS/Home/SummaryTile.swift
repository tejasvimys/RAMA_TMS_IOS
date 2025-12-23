    //
//  SummaryTile.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/22/25.
//

import SwiftUI

struct SummaryTile: View {
    @State private var summary: DaySummaryDto?
    @State private var loading = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.purple)
            }
            
            if loading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let s = summary {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today's Summary")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(s.totalAmount, specifier: "%.2f")")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Count")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(s.count)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("No donations today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.purple.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .onAppear(perform: loadSummary)
    }
    
    func loadSummary() {
        loading = true
        Task {
            do {
                let res = try await QuickDonationApi.shared.getTodaySummary()
                await MainActor.run {
                    summary = res
                    loading = false
                }
            } catch {
                await MainActor.run {
                    loading = false
                }
            }
        }
    }
}
