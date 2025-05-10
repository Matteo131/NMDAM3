//
//  NotificationManager.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 23/04/2025.
//

import Foundation
import UserNotifications
import Firebase

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
            }
            
            completion(granted)
        }
    }
    
    func scheduleChoreReminder(chore: Chore) {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Chore Reminder"
        content.body = "Don't forget: \(chore.title) is due today."
        content.sound = .default
        
        // Create trigger (one day before due date)
        let triggerDate = Calendar.current.date(byAdding: .day, value: -1, to: chore.dueDate) ?? chore.dueDate
        let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        
        // Create request
        let identifier = "chore-\(chore.id ?? UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling chore notification: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleExpenseReminder(expense: Expense) {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Payment Reminder"
        content.body = "There's a pending payment of $\(String(format: "%.2f", expense.amount)) for \(expense.title)."
        content.sound = .default
        
        // Create trigger (3 days after creation)
        guard let createdAt = expense.id.flatMap({ _ in Date() }) else { return }
        let triggerDate = Calendar.current.date(byAdding: .day, value: 3, to: createdAt) ?? createdAt
        let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        
        // Create request
        let identifier = "expense-\(expense.id ?? UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling expense notification: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func scheduleGroceryReminder(forHousehold householdId: String) {
        // Create weekly grocery reminder
        let content = UNMutableNotificationContent()
        content.title = "Grocery Shopping Reminder"
        content.body = "Check your grocery list before shopping!"
        content.sound = .default
        
        // Create trigger for Saturday morning
        var dateComponents = DateComponents()
        dateComponents.weekday = 7 // Saturday
        dateComponents.hour = 10
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request
        let identifier = "grocery-\(householdId)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling grocery notification: \(error.localizedDescription)")
            }
        }
    }
    
    // Method to create app notifications in Firestore
    func createNotification(
        title: String,
        body: String,
        type: NotificationType,
        relatedItemId: String? = nil,
        recipientId: String
    ) {
        let db = Firestore.firestore()
        
        let notificationData: [String: Any] = [
            "title": title,
            "body": body,
            "type": type.rawValue,
            "relatedItemId": relatedItemId ?? NSNull(),
            "sentAt": Timestamp(date: Date()),
            "isRead": false,
            "recipientId": recipientId
        ]
        
        db.collection("notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("Error creating notification: \(error.localizedDescription)")
            }
        }
    }
}
