//
//  SettlementsView.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 10/05/2025.
//


import SwiftUI

struct SettlementsView: View {
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    @State private var settlements: [ExpenseSettlement] = []
    @State private var isCalculating = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacing) {
                // Summary card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Settlement Summary")
                                .font(AppTheme.headlineFont)
                            Text("Simplify who owes whom")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button(action: calculateSettlements) {
                            Label("Calculate", systemImage: "arrow.triangle.2.circlepath")
                                .font(AppTheme.captionFont)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppTheme.primaryColor)
                                .foregroundColor(.white)
                                .cornerRadius(AppTheme.cornerRadius)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(AppTheme.cornerRadius)
                .shadow(color: AppTheme.cardShadow, radius: 3, x: 0, y: 1)
                .padding(.horizontal)
                
                // Settlements list
                if settlements.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.successColor)
                        
                        Text("All expenses are settled!")
                            .font(AppTheme.subheadlineFont)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    VStack(spacing: 12) {
                        ForEach(settlements) { settlement in
                            settlementRow(settlement)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(AppTheme.backgroundLight)
        .navigationTitle("Settlements")
        .onAppear {
            calculateSettlements()
        }
    }
    
    private func settlementRow(_ settlement: ExpenseSettlement) -> some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(AppTheme.primaryColor.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(settlement.fromUserName.prefix(1))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.primaryColor)
                )
            
            // Settlement details
            VStack(alignment: .leading, spacing: 4) {
                Text("\(settlement.fromUserName) owes \(settlement.toUserName)")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("$\(settlement.amount, specifier: "%.2f")")
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppTheme.primaryColor)
            }
            
            Spacer()
            
            Button(action: {
                markAsSettled(settlement)
            }) {
                Text("Settle")
                    .font(AppTheme.captionFont)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.successColor)
                    .foregroundColor(.white)
                    .cornerRadius(AppTheme.cornerRadius)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: AppTheme.cardShadow, radius: 3, x: 0, y: 1)
    }
    
    private func calculateSettlements() {
        isCalculating = true
        
        // Fetch fresh data
        viewModel.fetchExpenses(householdId: householdId)
        viewModel.fetchHouseholdMembers(householdId: householdId)
        
        // Calculate after a short delay to ensure data is loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let calculatedSettlements = SettlementCalculator.calculateSettlements(
                expenses: viewModel.expenses,
                members: viewModel.householdMembers
            )
            
            self.settlements = calculatedSettlements
            self.isCalculating = false
        }
    }
    
    private func markAsSettled(_ settlement: ExpenseSettlement) {
        // In a real app, this would update the expense records in Firebase
        // For now, we'll just remove it from the list
        settlements.removeAll { $0.id == settlement.id }
        
        // You would typically update Firebase here
        // updateExpenseSettlement(settlement)
    }
}