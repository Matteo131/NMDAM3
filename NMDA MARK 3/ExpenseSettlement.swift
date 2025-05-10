//
//  ExpenseSettlement.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 10/05/2025.
//

import Foundation

struct ExpenseSettlement: Identifiable, Codable {
    var id: String?
    var fromUserId: String
    var fromUserName: String
    var toUserId: String
    var toUserName: String
    var amount: Double
    var createdAt: Date
    var settledAt: Date?
    var householdId: String
    
    var isSettled: Bool {
        return settledAt != nil
    }
}

class SettlementCalculator {
    static func calculateSettlements(expenses: [Expense], members: [HouseholdMember]) -> [ExpenseSettlement] {
        var balances: [String: Double] = [:]
        
        // Initialize balances
        for member in members {
            balances[member.id ?? ""] = 0
        }
        
        // Calculate who owes what
        for expense in expenses {
            let paidById = expense.paidBy
            let amountPerPerson = expense.amountPerPerson
            
            // Person who paid gets positive balance
            balances[paidById] = (balances[paidById] ?? 0) + expense.amount
            
            // People who need to pay get negative balance
            for personId in expense.splitAmong {
                if expense.settled[personId] == false {
                    balances[personId] = (balances[personId] ?? 0) - amountPerPerson
                }
            }
        }
        
        // Calculate optimal settlements
        var settlements: [ExpenseSettlement] = []
        var creditors: [(String, Double)] = []
        var debtors: [(String, Double)] = []
        
        // Separate creditors and debtors
        for (userId, balance) in balances {
            if balance > 0.01 {
                creditors.append((userId, balance))
            } else if balance < -0.01 {
                debtors.append((userId, -balance))
            }
        }
        
        // Sort for optimal matching
        creditors.sort { $0.1 > $1.1 }
        debtors.sort { $0.1 > $1.1 }
        
        // Create settlements
        var i = 0, j = 0
        while i < creditors.count && j < debtors.count {
            let creditor = creditors[i]
            let debtor = debtors[j]
            
            let settlementAmount = min(creditor.1, debtor.1)
            
            if settlementAmount > 0.01 {
                let creditorName = members.first { $0.id == creditor.0 }?.displayName ?? "Unknown"
                let debtorName = members.first { $0.id == debtor.0 }?.displayName ?? "Unknown"
                
                let settlement = ExpenseSettlement(
                    fromUserId: debtor.0,
                    fromUserName: debtorName,
                    toUserId: creditor.0,
                    toUserName: creditorName,
                    amount: settlementAmount,
                    createdAt: Date(),
                    householdId: ""
                )
                settlements.append(settlement)
            }
            
            creditors[i].1 -= settlementAmount
            debtors[j].1 -= settlementAmount
            
            if creditors[i].1 <= 0.01 { i += 1 }
            if debtors[j].1 <= 0.01 { j += 1 }
        }
        
        return settlements
    }
}
