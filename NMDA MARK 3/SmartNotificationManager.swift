//
//  SmartNotificationManager.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 13/06/2025.
//

import Foundation
import UserNotifications
import Firebase
import FirebaseAuth



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
    
    // MARK: - Dynamic Context-Based Notifications
    
    func scheduleContextualNotification(
        title: String,
        body: String,
        triggerDate: Date,
        identifier: String,
        householdId: String? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        if let householdId = householdId {
            content.userInfo = ["householdId": householdId]
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: triggerDate.timeIntervalSinceNow,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Smart Urgency Detection
    
    func evaluateAndScheduleUrgentNotifications(
        chores: [Chore],
        expenses: [Expense],
        events: [Event],
        householdId: String
    ) {
        let now = Date()
        let calendar = Calendar.current
        
        // Overdue chores - immediate notification
        let overdueChores = chores.filter {
            !$0.isCompleted && $0.dueDate < now
        }
        
        if !overdueChores.isEmpty {
            scheduleContextualNotification(
                title: "Overdue chores! ⏰",
                body: "You have \(overdueChores.count) overdue chore\(overdueChores.count == 1 ? "" : "s"). Your roommates are counting on you!",
                triggerDate: Date().addingTimeInterval(300), // 5 minutes from now
                identifier: "overdue-chores-urgent",
                householdId: householdId
            )
        }
        
        // Bills due soon - 3 days before due
        let unsettledExpenses = expenses.filter { !$0.settled.values.allSatisfy { $0 } }
        if !unsettledExpenses.isEmpty {
            scheduleContextualNotification(
                title: "Time to settle up! 💰",
                body: "You have \(unsettledExpenses.count) expense\(unsettledExpenses.count == 1 ? "" : "s") waiting to be settled.",
                triggerDate: Date().addingTimeInterval(600), // 10 minutes from now
                identifier: "unsettled-expenses",
                householdId: householdId
            )
        }
        
        // Today's chores due soon
        let todayChores = chores.filter {
            !$0.isCompleted && calendar.isDateInToday($0.dueDate)
        }
        
        if !todayChores.isEmpty {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            
            for chore in todayChores {
                let timeUntilDue = chore.dueDate.timeIntervalSinceNow
                if timeUntilDue > 0 && timeUntilDue <= 7200 { // Within 2 hours
                    scheduleContextualNotification(
                        title: "Chore due soon! 🏃‍♂️",
                        body: "\(chore.title) is due at \(formatter.string(from: chore.dueDate))",
                        triggerDate: chore.dueDate.addingTimeInterval(-1800), // 30 minutes before
                        identifier: "chore-due-soon-\(chore.id ?? "")",
                        householdId: householdId
                    )
                }
            }
        }
        
        // Upcoming events today
        let todayEvents = events.filter {
            calendar.isDateInToday($0.startDate) && $0.startDate > now
        }
        
        for event in todayEvents {
            let timeUntilEvent = event.startDate.timeIntervalSinceNow
            if timeUntilEvent > 0 && timeUntilEvent <= 3600 { // Within 1 hour
                scheduleContextualNotification(
                    title: "Event starting soon! 📅",
                    body: "\(event.title) starts in \(Int(timeUntilEvent/60)) minutes",
                    triggerDate: event.startDate.addingTimeInterval(-900), // 15 minutes before
                    identifier: "event-soon-\(event.id ?? "")",
                    householdId: householdId
                )
            }
        }
    }
    
    // MARK: - Positive Reinforcement Notifications
    
    func schedulePositiveReinforcement(for achievement: String, householdId: String) {
        let achievements = [
            "first_chore": ("Great start! 🎉", "You completed your first chore! Your roommates appreciate you."),
            "chore_streak": ("You're on fire! 🔥", "3 chores completed this week! Keep up the great work."),
            "bill_splitter": ("Money management pro! 💰", "Thanks for keeping track of expenses. You're making everyone's life easier."),
            "grocery_hero": ("Shopping champion! 🛒", "Your grocery contributions keep the household running smoothly."),
        ]
        
        if let (title, body) = achievements[achievement] {
            scheduleContextualNotification(
                title: title,
                body: body,
                triggerDate: Date().addingTimeInterval(1800), // 30 minutes from now
                identifier: "achievement-\(achievement)",
                householdId: householdId
            )
        }
    }
    
    // MARK: - Semester-Specific Notifications
    
    func scheduleSemesterNotifications() {
        // Back to school reminder (Late August)
        scheduleSeasonalNotification(
            title: "New semester, fresh start! 📚",
            body: "Time to get organized with your roommates. Set up chores and coordinate for the new term!",
            month: 8,
            day: 25,
            hour: 10,
            identifier: "back-to-school"
        )
        
        // Mid-semester check-in (October)
        scheduleSeasonalNotification(
            title: "Mid-semester check-in 📋",
            body: "How's the household routine going? Time to review and adjust your system!",
            month: 10,
            day: 15,
            hour: 18,
            identifier: "mid-semester-checkin"
        )
        
        // Finals prep (November/December)
        scheduleSeasonalNotification(
            title: "Finals season prep! 📖",
            body: "Keep your living space organized during crunch time. Quick chores = better study environment!",
            month: 11,
            day: 20,
            hour: 9,
            identifier: "finals-prep"
        )
        
        // Spring semester start (January)
        scheduleSeasonalNotification(
            title: "New year, new habits! ✨",
            body: "Fresh semester = fresh household goals. Plan your spring routine together!",
            month: 1,
            day: 15,
            hour: 11,
            identifier: "spring-semester"
        )
        
        // End of year moving prep (April/May)
        scheduleSeasonalNotification(
            title: "Moving season prep 📦",
            body: "Start planning for end-of-term moves. Coordinate cleaning and settling final expenses!",
            month: 4,
            day: 15,
            hour: 16,
            identifier: "moving-prep"
        )
    }
    
    private func scheduleSeasonalNotification(
        title: String,
        body: String,
        month: Int,
        day: Int,
        hour: Int,
        identifier: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Intelligent Batching
    
    func scheduleIntelligentDigest(
        chores: [Chore],
        expenses: [Expense],
        groceryItems: [GroceryItem],
        events: [Event],
        householdId: String
    ) {
        let pendingChores = chores.filter { !$0.isCompleted }
        let pendingExpenses = expenses.filter { !$0.settled.values.allSatisfy { $0 } }
        let pendingGroceries = groceryItems.filter { !$0.isCompleted }
        let upcomingEvents = events.filter { $0.startDate > Date() && $0.startDate < Date().addingTimeInterval(86400 * 7) }
        
        // Only send digest if there's meaningful content
        let totalPendingItems = pendingChores.count + pendingExpenses.count + pendingGroceries.count + upcomingEvents.count
        
        if totalPendingItems >= 3 {
            var digestBody = ""
            
            if !pendingChores.isEmpty {
                digestBody += "\(pendingChores.count) pending chore\(pendingChores.count == 1 ? "" : "s")"
            }
            
            if !pendingExpenses.isEmpty {
                if !digestBody.isEmpty { digestBody += ", " }
                digestBody += "\(pendingExpenses.count) expense\(pendingExpenses.count == 1 ? "" : "s") to settle"
            }
            
            if !pendingGroceries.isEmpty {
                if !digestBody.isEmpty { digestBody += ", " }
                digestBody += "\(pendingGroceries.count) grocery item\(pendingGroceries.count == 1 ? "" : "s")"
            }
            
            if !upcomingEvents.isEmpty {
                if !digestBody.isEmpty { digestBody += ", " }
                digestBody += "\(upcomingEvents.count) upcoming event\(upcomingEvents.count == 1 ? "" : "s")"
            }
            
            scheduleContextualNotification(
                title: "Your household update 📱",
                body: digestBody + ". Tap to see details!",
                triggerDate: Date().addingTimeInterval(3600), // 1 hour from now
                identifier: "intelligent-digest",
                householdId: householdId
            )
        }
    }
    
    // MARK: - User Preferences and Smart Timing
    
    func getOptimalNotificationTime(for userId: String, defaultHour: Int) -> Int {
        // In a real app, this would learn from user behavior
        // For now, use smart defaults based on student schedules
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        
        // Adjust timing based on weekday
        if weekday == 1 || weekday == 7 { // Weekend
            return max(defaultHour + 1, 9) // Later on weekends, but not before 9 AM
        } else { // Weekday
            return max(defaultHour, 8) // Not before 8 AM on weekdays
        }
    }
    
    func shouldSendNotification(

        type: NotificationType,

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
    
    // MARK: - Integration with User Actions
    
    func handleNotificationResponse(
        identifier: String,
        actionIdentifier: String,
        userInfo: [AnyHashable: Any]
    ) {
        guard let householdId = userInfo["householdId"] as? String else { return }
        
        switch actionIdentifier {
        case "MARK_COMPLETE":
            // Handle quick completion actions
            if identifier.hasPrefix("chore-") {
                // Extract chore ID and mark as complete
                handleQuickChoreCompletion(identifier: identifier, householdId: householdId)
            }
            
        case "SNOOZE":
            // Reschedule notification for later
            rescheduleNotification(identifier: identifier, delay: 3600) // 1 hour later
            
        case "VIEW_DETAILS":
            // Deep link to specific screen
            handleDeepLink(identifier: identifier, householdId: householdId)
            
        default:
            break
        }
    }
    
    private func handleQuickChoreCompletion(identifier: String, householdId: String) {
        // Extract chore ID from identifier
        let choreId = String(identifier.dropFirst("chore-due-soon-".count))
        
        // Update in Firebase
        Firestore.firestore().collection("households").document(householdId)
            .collection("chores").document(choreId)
            .updateData([
                "isCompleted": true,
                "completedAt": Timestamp(date: Date())
            ]) { error in
                if error == nil {
                    // Send positive reinforcement
                    self.schedulePositiveReinforcement(for: "quick_complete", householdId: householdId)
                }
            }
    }
    
    private func rescheduleNotification(identifier: String, delay: TimeInterval) {
        // Remove current notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        
        // Reschedule with delay
        // Implementation would recreate the notification with new timing
    }
    
    private func handleDeepLink(identifier: String, householdId: String) {
        // Implementation would coordinate with the main app to navigate to specific screens
        // This would be handled by the main app coordinator
        NotificationCenter.default.post(
            name: NSNotification.Name("DeepLinkNotification"),
            object: nil,
            userInfo: [
                "identifier": identifier,
                "householdId": householdId
            ]
        )
    }
}


// MARK: - Supporting Enums

enum NotificationType: String {
    case chore, expense, grocery, event, digest, achievement, seasonal
}

enum NotificationPriority: Int {
    case low = 1
    case medium = 2
    case high = 3
    case urgent = 4
