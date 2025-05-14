//
//  Models.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 14/04/2025.
//

import Foundation
import FirebaseFirestore
import SwiftUI

// Model for a Chore
struct Chore: Identifiable, Codable {
    var id: String?
    var title: String
    var description: String?
    var assignedTo: String
    var dueDate: Date
    var isCompleted: Bool
    
    // Added fields for recurring chores
    var frequency: ChoreFrequency = .once
    var rotation: ChoreRotation?
    var history: [ChoreCompletion]?
    var isRecurring: Bool = false
    var recurrence: ChoreRecurrence?
    
    func nextOccurrence() -> Chore? {
        guard frequency != .once else { return nil }
        
        var newChore = self
        newChore.id = nil // New ID will be assigned when saved
        newChore.dueDate = frequency.nextDueDate(from: dueDate)
        newChore.isCompleted = false
        
        // Handle rotation if applicable
        if var rotation = rotation {
            newChore.assignedTo = rotation.nextRoommate()
            newChore.rotation = rotation
        }
        
        return newChore
    }
}

// Model for a GroceryItem
struct GroceryItem: Identifiable, Codable {
    var id: String?
    var name: String
    var category: String
    var addedBy: String
    var addedAt: Date
    var isCompleted: Bool
    
    // Added fields for enhanced grocery items
    var quantity: Int = 1
    var unit: String?
    var price: Double?
    var isShared: Bool = true
    var assignedTo: String?
    var note: String?
    
    var totalPrice: Double? {
        if let price = price {
            return price * Double(quantity)
        }
        return nil
    }
}

// Model for Household
struct Household: Identifiable, Codable {
    var id: String?
    var name: String
    var createdAt: Date
}

// Enum for chore frequency
enum ChoreFrequency: String, Codable {
    case once = "Once"
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    
    func nextDueDate(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .once:
            return date
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .day, value: 14, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        }
    }
}

// Structure for chore rotation between roommates
struct ChoreRotation: Codable {
    var roommates: [String]
    var currentIndex: Int
    
    mutating func nextRoommate() -> String {
        let roommate = roommates[currentIndex]
        currentIndex = (currentIndex + 1) % roommates.count
        return roommate
    }
}

// Structure for tracking chore completion history
struct ChoreCompletion: Codable {
    var date: Date
    var completedBy: String
    var dueDate: Date
    var onTime: Bool
}

struct Expense: Identifiable, Codable {
    var id: String?
    var title: String
    var amount: Double
    var paidBy: String
    var paidAt: Date
    var category: ExpenseCategory
    var splitType: SplitType
    var splitAmong: [String] // Array of user IDs
    var settled: [String: Bool] // Dictionary of user IDs and settlement status
    var notes: String?
    var receiptPath: String? // Changed from receiptURL
    
    var amountPerPerson: Double {
        guard !splitAmong.isEmpty else { return amount }
        return amount / Double(splitAmong.count)
    }
}

// Model for Calendar Event
struct Event: Identifiable, Codable {
    var id: String?
    var title: String
    var description: String?
    var startDate: Date
    var endDate: Date
    var location: String?
    var isAllDay: Bool
    var reminder: EventReminder?
    var attendees: [String] // Array of user IDs
    var createdBy: String
    var color: EventColor
    var recurrence: EventRecurrence?
}

enum EventColor: String, Codable, CaseIterable {
    case blue = "Blue"
    case green = "Green"
    case red = "Red"
    case orange = "Orange"
    case purple = "Purple"
    case teal = "Teal"
    
    var color: Color {
        switch self {
        case .blue: return Color.blue
        case .green: return Color.green
        case .red: return Color.red
        case .orange: return Color.orange
        case .purple: return Color.purple
        case .teal: return Color(hex: "008080")
        }
    }
}

enum EventReminder: String, Codable, CaseIterable {
    case none = "None"
    case atTime = "At time of event"
    case fiveMinutes = "5 minutes before"
    case fifteenMinutes = "15 minutes before"
    case thirtyMinutes = "30 minutes before"
    case oneHour = "1 hour before"
    case oneDay = "1 day before"
    
    func timeInterval() -> TimeInterval? {
        switch self {
        case .none: return nil
        case .atTime: return 0
        case .fiveMinutes: return -5 * 60
        case .fifteenMinutes: return -15 * 60
        case .thirtyMinutes: return -30 * 60
        case .oneHour: return -60 * 60
        case .oneDay: return -24 * 60 * 60
        }
    }
}

enum EventRecurrence: String, Codable, CaseIterable {
    case none = "Does not repeat"
    case daily = "Every day"
    case weekly = "Every week"
    case biweekly = "Every two weeks"
    case monthly = "Every month"
    case yearly = "Every year"
    
    func nextDate(from date: Date) -> Date? {
        guard self != .none else { return nil }
        
        let calendar = Calendar.current
        switch self {
        case .none:
            return nil
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date)
        case .biweekly:
            return calendar.date(byAdding: .day, value: 14, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date)
        }
    }
}

// Notification Model
struct AppNotification: Identifiable, Codable {
    var id: String?
    var title: String
    var body: String
    var type: AppNotificationType
    var relatedItemId: String? // ID of related item (chore, expense, etc.)
    var sentAt: Date
    var isRead: Bool = false
    var recipientId: String // User ID
}

enum AppNotificationType: String, Codable {
    case chore = "chore"
    case expense = "expense"
    case grocery = "grocery"
    case event = "event"
    case household = "household"
    case system = "system"
    
    var icon: String {
        switch self {
        case .chore: return "checkmark.circle.fill"
        case .expense: return "dollarsign.circle.fill"
        case .grocery: return "cart.fill"
        case .event: return "calendar"
        case .household: return "house.fill"
        case .system: return "bell.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .chore: return Color.blue
        case .expense: return Color.green
        case .grocery: return Color.orange
        case .event: return Color.purple
        case .household: return Color.pink
        case .system: return Color.gray
        }
    }
}

struct HouseholdMember: Identifiable, Codable {
    var id: String? // User ID
    var displayName: String
    var email: String
    var role: HouseholdRole
    var joinedAt: Date
    var profileImageURL: String?
}

enum HouseholdRole: String, Codable, CaseIterable {
    case owner = "Owner"
    case admin = "Admin"
    case member = "Member"
    
    var canInvite: Bool {
        self == .owner || self == .admin
    }
    
    var canRemoveMembers: Bool {
        self == .owner || self == .admin
    }
    
    var canEditHousehold: Bool {
        self == .owner || self == .admin
    }
    
    var canDeleteHousehold: Bool {
        self == .owner
    }
}

struct HouseholdInvitation: Identifiable, Codable {
    var id: String?
    var householdId: String
    var householdName: String
    var invitedBy: String // User ID of person who sent invite
    var invitedByName: String
    var inviteeEmail: String
    var status: InvitationStatus
    var createdAt: Date
    var expiresAt: Date
    var code: String // Unique invite code
}

enum InvitationStatus: String, Codable {
    case pending = "Pending"
    case accepted = "Accepted"
    case declined = "Declined"
    case expired = "Expired"
}

enum ExpenseCategory: String, Codable, CaseIterable {
    case rent = "Rent"
    case utilities = "Utilities"
    case groceries = "Groceries"
    case dining = "Dining"
    case entertainment = "Entertainment"
    case transportation = "Transportation"
    case household = "Household"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .rent: return "house.fill"
        case .utilities: return "bolt.fill"
        case .groceries: return "cart.fill"
        case .dining: return "fork.knife"
        case .entertainment: return "tv.fill"
        case .transportation: return "car.fill"
        case .household: return "doc.text.fill"
        case .other: return "square.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .rent: return Color.blue
        case .utilities: return Color.yellow
        case .groceries: return Color.green
        case .dining: return Color.orange
        case .entertainment: return Color.purple
        case .transportation: return Color.gray
        case .household: return Color.pink
        case .other: return Color.black
        }
    }
}

enum SplitType: String, Codable, CaseIterable {
    case equal = "Split Equally"
    case percentage = "Split by Percentage"
    case custom = "Custom Amounts"
}

// Add to Models.swift
struct RoommateActivity: Identifiable {
    var id: String
    var userName: String
    var actionVerb: String
    var itemName: String
    var itemType: String
    var timestamp: Date
}
