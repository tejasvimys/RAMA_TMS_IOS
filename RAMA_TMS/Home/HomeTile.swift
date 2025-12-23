//
//  HomeTile.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/21/25.
//

import SwiftUI

struct HomeTile: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundColor(RamaTheme.primary)

            Text(title)
                .font(.subheadline) 
                .foregroundColor(.primary)
        }
        .frame(width: 140, height: 120)
        .background(RamaTheme.card)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
