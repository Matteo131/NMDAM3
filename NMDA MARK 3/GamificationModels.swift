//
//  GamificationModels.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 05/05/2025.
//

import SwiftUI
import FirebaseFirestore

// MARK: - Gamification Models

struct UserLevel: Identifiable, Codable {
    var id: Int
    var name: String
    var requiredPoints: Int
    var icon: String
    var color: String
    
    var colorValue: Color {
        Color(hex: color)
    }
    
    static let levels: [UserLevel] = [
        UserLevel(id: 1, name: "Rookie Roomie", requiredPoints: 0, icon: "star", color: "5F65F5"),
        UserLevel(id: 2, name: "Reliable Resident", requiredPoints: 100, icon: "star.fill", color: "00C2A8"),
        UserLevel(id: 3, name: "Chore Champion", requiredPoints: 250, icon: "star.circle.fill", color: "FF6E91"),
        UserLevel(id: 4, name: "Dorm Dynamo", requiredPoints: 500, icon: "sparkles", color: "FAD02C"),
        UserLevel(id: 5, name: "Household Hero", requiredPoints: 1000, icon: "crown.fill", color: "FF5252")
    ]
    
    static func currentLevel(points: Int) -> UserLevel {
        let sortedLevels = levels.sorted(by: { $0.requiredPoints < $1.requiredPoints })
        var highestLevel = sortedLevels.first!
        
        for level in sortedLevels {
            if points >= level.requiredPoints {
                highestLevel = level
            } else {
                break
            }
        }
        
        return highestLevel
    }
    
    static func nextLevel(points: Int) -> UserLevel? {
        let sortedLevels = levels.sorted(by: { $0.requiredPoints < $1.requiredPoints })
        
        for level in sortedLevels {
            if points < level.requiredPoints {
                return level
            }
        }
        
        return nil
    }
    
    static func progressToNextLevel(points: Int) -> Double {
        let current = currentLevel(points: points)
        
        if let next = nextLevel(points: points) {
            let totalNeeded = next.requiredPoints - current.requiredPoints
            let userProgress = points - current.requiredPoints
            
            return Double(userProgress) / Double(totalNeeded)
        }
        
        return 1.0 // Max level
    }
}

struct Achievement: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var icon: String
    var points: Int
    var category: AchievementCategory
    var isUnlocked: Bool
    var unlockedAt: Date?
    var progress: Double // 0 to 1
    
    var color: Color {
        switch category {
        case .chores:
            return AppTheme.primaryColor
        case .grocery:
            return AppTheme.secondaryColor
        case .expenses:
            return AppTheme.accentColor
        case .social:
            return AppTheme.warningColor
        case .special:
            return AppTheme.dangerColor
        }
    }
}

enum AchievementCategory: String, Codable, CaseIterable {
    case chores = "Chores"
    case grocery = "Grocery"
    case expenses = "Expenses"
    case social = "Social"
    case special = "Special"
    
    var icon: String {
        switch self {
        case .chores:
            return "checkmark.circle.fill"
        case .grocery:
            return "cart.fill"
        case .expenses:
            return "dollarsign.circle.fill"
        case .social:
            return "person.2.fill"
        case .special:
            return "star.fill"
        }
    }
    var color: Color {
        switch self {
        case .chores:
            return AppTheme.primaryColor
        case .grocery:
            return AppTheme.secondaryColor
        case .expenses:
            return AppTheme.accentColor
        case .social:
            return AppTheme.warningColor
        case .special:
            return AppTheme.dangerColor
        }
    }
}

// MARK: - Activity Feed Item

struct ActivityFeedItem: Identifiable, Codable {
    var id: String
    var userId: String
    var userName: String
    var actionType: ActivityType
    var objectType: ActivityObjectType
    var objectId: String
    var objectName: String
    var points: Int
    var timestamp: Date
    var isHighlighted: Bool
    
    var description: String {
        switch actionType {
        case .add:
            return "added \(objectName)"
        case .complete:
            return "completed \(objectName)"
        case .pay:
            return "paid \(objectName)"
        case .unlock:
            return "unlocked \(objectName)"
        case .join:
            return "joined \(objectName)"
        }
    }
    
    var icon: String {
        objectType.icon
    }
    
    var color: Color {
        objectType.color
    }
}

enum ActivityType: String, Codable, CaseIterable {
    case add
    case complete
    case pay
    case unlock
    case join
}

enum ActivityObjectType: String, Codable, CaseIterable {
    case chore
    case grocery
    case expense
    case achievement
    case household
    
    var icon: String {
        switch self {
        case .chore:
            return "checkmark.circle.fill"
        case .grocery:
            return "cart.fill"
        case .expense:
            return "dollarsign.circle.fill"
        case .achievement:
            return "star.fill"
        case .household:
            return "house.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .chore:
            return AppTheme.primaryColor
        case .grocery:
            return AppTheme.secondaryColor
        case .expense:
            return AppTheme.accentColor
        case .achievement:
            return AppTheme.warningColor
        case .household:
            return AppTheme.successColor
        }
    }
}

struct UserStats: Codable {
    var points: Int = 0
    var choresDone: Int = 0
    var expensesPaid: Double = 0
    var groceryItemsBought: Int = 0
    var achievements: [String] = []
    var streakDays: Int = 0
    var lastActive: Date?
    
    var currentLevel: UserLevel {
        UserLevel.currentLevel(points: points)
    }
    
    var nextLevel: UserLevel? {
        UserLevel.nextLevel(points: points)
    }
    
    var progressToNextLevel: Double {
        UserLevel.progressToNextLevel(points: points)
    }
}

// Extension for saving/loading from Firestore
extension UserStats {
    static func fetch(for userId: String, in householdId: String, completion: @escaping (UserStats?) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("households").document(householdId)
            .collection("userStats").document(userId)
            .getDocument { snapshot, error in
                guard let data = snapshot?.data() else {
                    completion(UserStats())
                    return
                }
                
                let stats = UserStats(
                    points: data["points"] as? Int ?? 0,
                    choresDone: data["choresDone"] as? Int ?? 0,
                    expensesPaid: data["expensesPaid"] as? Double ?? 0,
                    groceryItemsBought: data["groceryItemsBought"] as? Int ?? 0,
                    achievements: data["achievements"] as? [String] ?? [],
                    streakDays: data["streakDays"] as? Int ?? 0,
                    lastActive: (data["lastActive"] as? Timestamp)?.dateValue()
                )
                
                completion(stats)
            }
    }
    
    func save(for userId: String, in householdId: String, completion: ((Error?) -> Void)? = nil) {
        let db = Firestore.firestore()
        
        let data: [String: Any] = [
            "points": points,
            "choresDone": choresDone,
            "expensesPaid": expensesPaid,
            "groceryItemsBought": groceryItemsBought,
            "achievements": achievements,
            "streakDays": streakDays,
            "lastActive": Timestamp(date: lastActive ?? Date())
        ]
        
        db.collection("households").document(householdId)
            .collection("userStats").document(userId)
            .setData(data, merge: true, completion: completion)
    }
    
    mutating func addPoints(_ newPoints: Int, complete: Bool = true) {
        points += newPoints
        
        // Update streak
        let now = Date()
        if let last = lastActive {
            let calendar = Calendar.current
            if calendar.isDateInToday(last) {
                // Already logged in today, do nothing
            } else if calendar.isDateInYesterday(last) {
                // Continued streak
                streakDays += 1
            } else {
                // Broken streak, restart
                streakDays = 1
            }
        } else {
            // First time, start streak
            streakDays = 1
        }
        
        lastActive = now
    }
}
