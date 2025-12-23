//
//  ReportContentView.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/23/25.
//

import SwiftUI

struct ReportContentView: View {
    let report: EndOfDayReport
    
    var body: some View {
        VStack(spacing: 20) {
            summaryCardsView
            donationBreakdownView
            paymentMethodBreakdownView
            donationListView
        }
    }
    
    private var summaryCardsView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SummaryCard(
                    icon: "dollarsign.circle.fill",
                    title: "Total Amount",
                    value: String(format: "$%.2f", report.totalAmount),
                    color: .green
                )
                
                SummaryCard(
                    icon: "number.circle.fill",
                    title: "Total Count",
                    value: "\(report.totalCount)",
                    color: .blue
                )
            }
            
            HStack(spacing: 12) {
                SummaryCard(
                    icon: "person.2.fill",
                    title: "Unique Donors",
                    value: "\(report.uniqueDonors)",
                    color: .orange
                )
                
                SummaryCard(
                    icon: "chart.bar.fill",
                    title: "Avg Donation",
                    value: String(format: "$%.2f", report.averageDonation),
                    color: .purple
                )
            }
        }
    }
    
    private var donationBreakdownView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(RamaTheme.primary)
                Text("Donation Type Breakdown")
                    .font(.headline)
                    .foregroundColor(RamaTheme.primary)
            }
            
            ForEach(report.byDonationType) { breakdown in
                DonationBreakdownRow(
                    type: breakdown.type,
                    amount: breakdown.amount,
                    count: breakdown.count,
                    percentage: (breakdown.amount / report.totalAmount) * 100
                )
            }
        }
        .padding()
        .background(RamaTheme.card)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private var paymentMethodBreakdownView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(RamaTheme.primary)
                Text("Payment Method Breakdown")
                    .font(.headline)
                    .foregroundColor(RamaTheme.primary)
            }
            
            ForEach(report.byPaymentMethod) { breakdown in
                PaymentMethodRow(
                    method: breakdown.type,
                    amount: breakdown.amount,
                    count: breakdown.count
                )
            }
        }
        .padding()
        .background(RamaTheme.card)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private var donationListView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet.rectangle.fill")
                    .foregroundColor(RamaTheme.primary)
                Text("All Donations (\(report.donations.count))")
                    .font(.headline)
                    .foregroundColor(RamaTheme.primary)
            }
            
            ForEach(report.donations) { donation in
                DonationRowCard(donation: donation)
            }
        }
        .padding()
        .background(RamaTheme.card)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    let sampleReport = EndOfDayReport(
        id: "1",
        date: Date(),
        totalAmount: 5250.00,
        totalCount: 25,
        uniqueDonors: 18,
        averageDonation: 210.00,
        byDonationType: [
            DonationTypeBreakdown(type: "General", amount: 2000.00, count: 10),
            DonationTypeBreakdown(type: "Building Fund", amount: 1500.00, count: 8),
            DonationTypeBreakdown(type: "Annadana", amount: 1250.00, count: 5),
            DonationTypeBreakdown(type: "Seva", amount: 500.00, count: 2)
        ],
        byPaymentMethod: [
            PaymentMethodBreakdown(type: "Cash", amount: 2500.00, count: 15),
            PaymentMethodBreakdown(type: "Check", amount: 1500.00, count: 6),
            PaymentMethodBreakdown(type: "Zelle", amount: 1000.00, count: 3),
            PaymentMethodBreakdown(type: "CreditCard", amount: 250.00, count: 1)
        ],
        donations: [
            DonationDetail(
                id: "1",
                donorName: "John Smith",
                amount: 500.00,
                donationType: "General",
                paymentMode: "Cash",
                referenceNo: nil,
                timestamp: Date(),
                notes: nil
            ),
            DonationDetail(
                id: "2",
                donorName: "Jane Doe",
                amount: 1000.00,
                donationType: "Building Fund",
                paymentMode: "Check",
                referenceNo: "CHK-12345",
                timestamp: Date(),
                notes: nil
            )
        ],
        collectorName: "Collector Name",
        collectorEmail: "collector@example.com"
    )
    
    ScrollView {
        ReportContentView(report: sampleReport)
            .padding()
    }
    .background(RamaTheme.background)
}
