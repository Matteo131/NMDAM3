//
//  NotificationsView.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 23/04/2025.
//

import SwiftUI
import Firebase

struct NotificationsView: View {
    @ObservedObject var viewModel: FirestoreViewModel
    @State private var showUnreadOnly = false
    
    var body: some View {
        VStack {
            // Filter toggle
            HStack {
                Toggle("Show unread only", isOn: $showUnreadOnly)
                    .toggleStyle(SwitchToggleStyle(tint: AppTheme.primaryColor))
                
                Spacer()
                
                if !viewModel.notifications.isEmpty {
                    Button("Mark all as read") {
                        markAllAsRead()
                    }
                    .disabled(viewModel.notifications.filter { !$0.isRead }.isEmpty)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            if viewModel.isLoading {
                ProgressView("Loading notifications...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredNotifications.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No notifications")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    if showUnreadOnly {
                        Button("Show all notifications") {
                            showUnreadOnly = false
                        }
                        .foregroundColor(AppTheme.primaryColor)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredNotifications) { notification in
                        NotificationRow(notification: notification)
                            .onTapGesture {
                                markAsRead(notification)
                                navigateToRelatedItem(notification)
                            }
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .onAppear {
            viewModel.fetchNotifications()
        }
    }
    
    var filteredNotifications: [AppNotification] {
        if showUnreadOnly {
            return viewModel.notifications.filter { !$0.isRead }
        } else {
            return viewModel.notifications
        }
    }
    
    private func markAsRead(_ notification: AppNotification) {
        guard let notificationId = notification.id, !notification.isRead else { return }
        
        viewModel.markNotificationAsRead(notificationId: notificationId)
    }
    
    private func markAllAsRead() {
        viewModel.markAllNotificationsAsRead()
    }
    
    private func navigateToRelatedItem(_ notification: AppNotification) {
        // In a real app, this would navigate to the relevant screen
        // e.g., if it's a chore notification, navigate to that chore's details
        print("Navigate to \(notification.type) with ID: \(notification.relatedItemId ?? "none")")
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    
    var body: some View {
        HStack(spacing: 16) {
            // Notification icon
            ZStack {
                Circle()
                    .fill(notification.type.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: notification.type.icon)
                    .foregroundColor(notification.type.color)
            }
            
            // Notification content
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(notification.body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(timeAgo(from: notification.sentAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Unread indicator
            if !notification.isRead {
                Circle()
                    .fill(AppTheme.primaryColor)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .background(notification.isRead ? Color.clear : Color(.systemGray6).opacity(0.3))
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
