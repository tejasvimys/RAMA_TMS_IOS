//
//  ReportComponentViews.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/23/25.
//

import SwiftUI

// MARK: - Header View
struct ReportHeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 50))
                .foregroundColor(RamaTheme.primary)
            
            Text("Daily Collection Report")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(RamaTheme.primary)
            
            Text("View and send donation summary")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }
}

// MARK: - Date Picker Card
struct DatePickerCard: View {
    @Binding var selectedDate: Date
    let onDateChange: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(RamaTheme.primary)
                Text("Select Date")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            DatePicker(
                "Report Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .tint(RamaTheme.primary)
            .onChange(of: selectedDate) { _, _ in
                onDateChange()
            }
        }
        .padding()
        .background(RamaTheme.card)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(RamaTheme.primary)
            Text("Loading report...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Retry", action: onRetry)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(RamaTheme.primary)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RamaTheme.card)
        .cornerRadius(16)
    }
}

// MARK: - Empty Report View
struct EmptyReportView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.fill")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No donations recorded for this date")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RamaTheme.card)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Donation Breakdown Row
struct DonationBreakdownRow: View {
    let type: String
    let amount: Double
    let count: Int
    let percentage: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(type)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "$%.2f", amount))
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("\(count) donations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(RamaTheme.primary)
                        .frame(width: geometry.size.width * (percentage / 100), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Payment Method Row
struct PaymentMethodRow: View {
    let method: String
    let amount: Double
    let count: Int
    
    var body: some View {
        HStack {
            Image(systemName: paymentIcon(for: method))
                .font(.title3)
                .foregroundColor(RamaTheme.primary)
                .frame(width: 30)
            
            Text(method)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", amount))
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text("\(count) transactions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func paymentIcon(for method: String) -> String {
        switch method {
        case "Cash": return "dollarsign.circle.fill"
        case "Check": return "doc.text.fill"
        case "Zelle": return "bolt.circle.fill"
        case "CreditCard": return "creditcard.fill"
        default: return "dollarsign.circle"
        }
    }
}

// MARK: - Donation Row Card
struct DonationRowCard: View {
    let donation: DonationDetail
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(donation.donorName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    Label(donation.donationType, systemImage: "tag.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(donation.paymentMode, systemImage: "creditcard.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let ref = donation.referenceNo {
                    Text("Ref: \(ref)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(donation.amount, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(RamaTheme.primary)
                
                Text(donation.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Report Actions View
struct ReportActionsView: View {
    @Binding var isSendingEmail: Bool
    @Binding var sendSuccess: Bool
    let onSendEmail: () -> Void
    let hasReport: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: onSendEmail) {
                HStack(spacing: 12) {
                    if isSendingEmail {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "envelope.fill")
                            .font(.title3)
                        Text("Send Report to Admins")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(hasReport && !isSendingEmail ? RamaTheme.primary : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(
                    color: hasReport && !isSendingEmail ? RamaTheme.primary.opacity(0.4) : Color.clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .disabled(isSendingEmail || !hasReport)
            
            if sendSuccess {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Report sent successfully!")
                }
                .foregroundColor(.green)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}
