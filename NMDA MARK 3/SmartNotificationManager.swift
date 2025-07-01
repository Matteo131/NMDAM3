import Foundation
import UserNotifications
import Firebase
import FirebaseAuth

// Define enums at the top level
enum SmartNotificationType: String {
    case chore, expense, grocery, event, digest, achievement, seasonal
}

enum NotificationPriority: Int {
    case low = 1
    case medium = 2
    case high = 3
    case urgent = 4
}

class SmartNotificationManager: ObservableObject {
    static let shared = SmartNotificationManager()
    
    private init() {}
    
    // MARK: - Smart Notification Scheduling
    
    func scheduleSmartNotifications(for householdId: String) {
        // Cancel existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule different types of student-focused notifications
        scheduleStudentReminders(householdId: householdId)
        scheduleContextualReminders(householdId: householdId)
        scheduleWeeklyDigest(householdId: householdId)
    }
    
    // MARK: - Student-Specific Reminders
    
    private func scheduleStudentReminders(householdId: String) {
        // Morning motivation (8 AM on weekdays)
        scheduleMorningMotivation()
        
        // Evening check-in (8 PM daily)
        scheduleEveningCheckIn(householdId: householdId)
        
        // Weekend planning (Friday 6 PM)
        scheduleWeekendPlanning()
        
        // Monthly bills reminder (25th of each month)
        scheduleMonthlyBillsReminder(householdId: householdId)
    }
    
    private func scheduleMorningMotivation() {
        let content = UNMutableNotificationContent()
        content.title = "Good morning! 🌅"
        content.body = "Ready to tackle today? Check your chores and see what's on the agenda."
        content.sound = .default
        
        // Schedule for 8 AM on weekdays
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        
        for weekday in 2...6 { // Monday to Friday
            dateComponents.weekday = weekday
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: "morning-motivation-\(weekday)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    private func scheduleEveningCheckIn(householdId: String) {
        let content = UNMutableNotificationContent()
        content.title = "End of day check-in 📝"
        content.body = "How did today go? Mark off completed chores and plan for tomorrow."
        content.sound = .default
        content.userInfo = ["action": "daily_check_in", "householdId": householdId]
        
        // Schedule for 8 PM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "evening-check-in",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleWeekendPlanning() {
        let content = UNMutableNotificationContent()
        content.title = "Weekend planning time! 📅"
        content.body = "Time to plan your weekend grocery run and catch up on chores."
        content.sound = .default
        
        // Schedule for Friday 6 PM
        var dateComponents = DateComponents()
        dateComponents.weekday = 6 // Friday
        dateComponents.hour = 18
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "weekend-planning",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleMonthlyBillsReminder(householdId: String) {
        let content = UNMutableNotificationContent()
        content.title = "Bills due soon! 💰"
        content.body = "Time to settle up with your roommates. Check pending expenses."
        content.sound = .default
        content.userInfo = ["action": "bills_reminder", "householdId": householdId]
        
        // Schedule for 25th of each month at 7 PM
        var dateComponents = DateComponents()
        dateComponents.day = 25
        dateComponents.hour = 19
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "monthly-bills",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Contextual Smart Notifications
    
    private func scheduleContextualReminders(householdId: String) {
        // Grocery reminder before typical shopping times
        scheduleGroceryReminders(householdId: householdId)
        
        // Study break chore suggestions
        scheduleStudyBreakReminders()
        
        // Social coordination reminders
        scheduleSocialReminders()
    }
    
    private func scheduleGroceryReminders(householdId: String) {
        let content = UNMutableNotificationContent()
        content.title = "Grocery run time? 🛒"
        content.body = "Perfect time for a grocery run! Check your shared list before heading out."
        content.sound = .default
        content.userInfo = ["action": "grocery_reminder", "householdId": householdId]
        
        // Schedule for weekends (Saturday 10 AM)
        var dateComponents = DateComponents()
        dateComponents.weekday = 7 // Saturday
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "grocery-reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleStudyBreakReminders() {
        let content = UNMutableNotificationContent()
        content.title = "Study break = productivity break! 📚"
        content.body = "Quick 15-minute chore break? It'll help you refocus when you get back to studying."
        content.sound = .default
        
        // Schedule for typical study times (weekday evenings)
        for weekday in 2...6 { // Monday to Friday
            for hour in [15, 19, 21] { // 3 PM, 7 PM, 9 PM
                var dateComponents = DateComponents()
                dateComponents.weekday = weekday
                dateComponents.hour = hour
                dateComponents.minute = 30
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                
                let request = UNNotificationRequest(
                    identifier: "study-break-\(weekday)-\(hour)",
                    content: content,
                    trigger: trigger
                )
                
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    private func scheduleSocialReminders() {
        let content = UNMutableNotificationContent()
        content.title = "Time to coordinate! 👥"
        content.body = "Planning anything fun this weekend? Add it to your household calendar."
        content.sound = .default
        
        // Schedule for Wednesday 6 PM (mid-week planning)
        var dateComponents = DateComponents()
        dateComponents.weekday = 4 // Wednesday
        dateComponents.hour = 18
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "social-coordination",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Weekly Digest
    
    private func scheduleWeeklyDigest(householdId: String) {
        let content = UNMutableNotificationContent()
        content.title = "Your week in review 📊"
        content.body = "See how you and your roommates did this week, and plan for the next!"
        content.sound = .default
        content.userInfo = ["action": "weekly_digest", "householdId": householdId]
        
        // Schedule for Sunday 7 PM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 19
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "weekly-digest",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Notification Throttling
    
    func shouldSendNotification(
        type: SmartNotificationType,
        priority: NotificationPriority,
        timeSinceLastNotification: TimeInterval
    ) -> Bool {
        // Implement intelligent notification throttling
        switch priority {
        case .urgent:
            return timeSinceLastNotification > 300 // 5 minutes minimum between urgent notifications
        case .high:
            return timeSinceLastNotification > 1800 // 30 minutes minimum
        case .medium:
            return timeSinceLastNotification > 3600 // 1 hour minimum
        case .low:
            return timeSinceLastNotification > 86400 // 1 day minimum
        }
    }
    
    // MARK: - Helper Methods
    
    func getOptimalNotificationTime(for userId: String, defaultHour: Int) -> Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        
        // Adjust timing based on weekday
        if weekday == 1 || weekday == 7 { // Weekend
            return max(defaultHour + 1, 9) // Later on weekends, but not before 9 AM
        } else { // Weekday
            return max(defaultHour, 8) // Not before 8 AM on weekdays
        }
    }
}
