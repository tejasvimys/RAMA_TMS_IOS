//
//  SplashView.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 12/21/25.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            RamaTheme.background
                .ignoresSafeArea()

            Image("rama-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 240)
        }
    }
}
