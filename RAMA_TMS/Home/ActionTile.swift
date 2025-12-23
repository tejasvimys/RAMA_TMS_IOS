//
//  ActionTile.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/21/25.
//

import SwiftUI

struct ActionTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    HStack(spacing: 16) {
        ActionTile(
            title: "Add Donation",
            subtitle: "Record new donation",
            icon: "plus.circle.fill",
            color: Color(red: 0.9, green: 0.49, blue: 0)
        )
        
        ActionTile(
            title: "EOD Report",
            subtitle: "Daily summary",
            icon: "doc.text.fill",
            color: Color(red: 0.4, green: 0.49, blue: 0.92)
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
