//
//  ChoreRecurrence.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 10/05/2025.
//

import Foundation

enum RecurrenceFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
}

struct ChoreRecurrence: Codable {
    var frequency: RecurrenceFrequency
    var daysOfWeek: [Int]? // For weekly: 0 = Sunday, 6 = Saturday
    var dayOfMonth: Int? // For monthly: 1-31
    var nextDueDate: Date
    
    func calculateNextDueDate(from currentDate: Date) -> Date {
        let calendar = Calendar.current
        
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
            
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: currentDate) ?? currentDate
            
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
        }
    }
}
