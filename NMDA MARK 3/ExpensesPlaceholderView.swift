//
//  ExpensesPlaceholderView.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 21/04/2025.
//

import SwiftUI

struct ExpensesComingSoonView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(AppTheme.primaryColor.opacity(0.5))
            
            Text("Expense Tracking")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Track expenses and split bills with roommates.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Text("Coming Soon")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppTheme.secondaryColor)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding()
        .navigationTitle("Expenses")
    }
}
