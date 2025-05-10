// In NotificationService.swift
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFunctions  // Add this import
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    private let db = Firestore.firestore()
    
    // Schedule local notification for chore
    func scheduleChoreReminder(chore: Chore, householdId: String) {
        let content = UNMutableNotificationContent()
        content.title = "Chore Reminder"
        content.body = "\(chore.title) is due today!"
        content.sound = .default
        
        // Schedule for 9 AM on due date
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: chore.dueDate)
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "chore-\(chore.id ?? UUID().uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // Send push notification via Cloud Function
    func sendPushNotification(to userId: String, title: String, body: String, data: [String: String] = [:]) {
        // Get user's FCM token
        db.collection("users").document(userId).getDocument { snapshot, error in
            guard let fcmToken = snapshot?.data()?["fcmToken"] as? String else { return }
            
            // Call your Cloud Function to send notification
            let functions = Functions.functions()
            functions.httpsCallable("sendPushNotification").call([
                "token": fcmToken,
                "title": title,
                "body": body,
                "data": data
            ]) { result, error in
                if let error = error {
                    print("Error sending notification: \(error)")
                }
            }
        }
    }
    
    // Alternative implementation without Cloud Functions
    func sendLocalNotification(title: String, body: String, after timeInterval: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending local notification: \(error)")
            }
        }
    }
}
