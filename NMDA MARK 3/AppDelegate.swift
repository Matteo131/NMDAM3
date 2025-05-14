// In AppDelegate.swift
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    SmartNotificationManager.shared.scheduleSmartNotifications(for: "default")
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Add push notification setup
        setupPushNotifications()
        
        // Schedule smart notifications
        SmartNotificationManager.shared.scheduleSmartNotifications(for: "default")
        
        return true
    }
    
    // Add this new method
    private func setupPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if granted {
                print("Notification permission granted")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        Messaging.messaging().delegate = self
    }
    
    // Add these delegate methods
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        // Save token to Firestore for the current user
        if let token = fcmToken, let userId = Auth.auth().currentUser?.uid {
            Firestore.firestore().collection("users").document(userId).updateData([
                "fcmToken": token
            ])
        }
    }
    
    // Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
