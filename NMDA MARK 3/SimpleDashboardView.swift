//
//  SimpleDashboardView.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 07/05/2025.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct SimpleDashboardView: View {
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacing) {
                // Household header
                if let household = viewModel.household {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome to")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Text(household.name)
                                .font(AppTheme.titleFont)
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        
                        Spacer()
                        
                        Text(Auth.auth().currentUser?.displayName ?? "Roommate")
                            .font(AppTheme.captionFont)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.primaryColor.opacity(0.1))
                            .foregroundColor(AppTheme.primaryColor)
                            .cornerRadius(AppTheme.cornerRadius)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(AppTheme.cornerRadius)
                    .shadow(color: AppTheme.cardShadow, radius: AppTheme.shadowRadius, x: 0, y: 2)
                    .padding(.horizontal)
                }
                
                // Quick action buttons
                quickActionButtons
                
                // Upcoming tasks
                upcomingTasksSection
                
                // Recent household activity
                recentActivitySection
            }
            .padding(.vertical)
        }
        .background(AppTheme.backgroundLight.ignoresSafeArea())
        .onAppear {
            loadData()
        }
    }
    
    private var quickActionButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacing) {
                quickActionButton(
                    title: "Add Chore",
                    icon: "checkmark.circle.fill",
                    color: AppTheme.primaryColor,
                    destination: AnyView(AddChoreView(viewModel: viewModel, householdId: householdId))
                )
                
                quickActionButton(
                    title: "Add Grocery",
                    icon: "cart.fill",
                    color: AppTheme.secondaryColor,
                    destination: AnyView(AddGroceryItemView(viewModel: viewModel, householdId: householdId))
                )
                
                quickActionButton(
                    title: "Add Event",
                    icon: "calendar",
                    color: AppTheme.accentColor,
                    destination: AnyView(AddEventView(viewModel: viewModel, householdId: householdId, initialDate: Date()))
                )
                
                quickActionButton(
                    title: "Add Expense",
                    icon: "dollarsign.circle.fill",
                    color: AppTheme.errorColor,
                    destination: AnyView(AddExpenseView(viewModel: viewModel, householdId: householdId))
                )
            }
            .padding(.horizontal)
        }
    }
    
    private var upcomingTasksSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            sectionHeader(title: "Upcoming Tasks", action: {})
            
            if viewModel.chores.isEmpty && viewModel.events.isEmpty {
                emptyStateCard(
                    message: "No upcoming tasks. Add some to get started!",
                    icon: "checkmark.circle"
                )
            } else {
                ForEach(upcomingItems.prefix(3)) { item in
                    upcomingTaskRow(item)
                }
                
                if upcomingItems.count > 3 {
                    Button("View All Tasks") {
                        // Navigate to all tasks
                    }
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.primaryColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            sectionHeader(title: "Recent Activity", action: {})
            
            if viewModel.recentActivity.isEmpty {
                emptyStateCard(
                    message: "No recent activity. Your household events will appear here.",
                    icon: "person.2.fill"
                )
            } else {
                ForEach(viewModel.recentActivity.prefix(3)) { activity in
                    activityRow(activity)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // Helper Views
    
    private func quickActionButton<Destination: View>(title: String, icon: String, color: Color, destination: Destination) -> some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(title)
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.textPrimary)
            }
            .frame(width: 100, height: 80)
            .background(Color.white)
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(color: AppTheme.cardShadow, radius: AppTheme.shadowRadius, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func sectionHeader(title: String, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.headlineFont)
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
            
            Button("See All") {
                action()
            }
            .font(AppTheme.captionFont)
            .foregroundColor(AppTheme.primaryColor)
        }
        .padding(.top, AppTheme.spacing)
    }
    
    private func emptyStateCard(message: String, icon: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppTheme.textTertiary)
            
            Text(message)
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: AppTheme.cardShadow, radius: AppTheme.shadowRadius, x: 0, y: 2)
    }
    
    private func upcomingTaskRow(_ item: UpcomingItem) -> some View {
        HStack(spacing: 16) {
            Image(systemName: item.icon)
                .font(.system(size: 20))
                .foregroundColor(item.typeColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                
                HStack {
                    Text(formatDate(item.dueDate))
                        .font(AppTheme.captionFont)
                        .foregroundColor(dueDateColor(item.dueDate))
                    
                    Text("•")
                        .foregroundColor(AppTheme.textTertiary)
                    
                    Text(item.type.rawValue)
                        .font(AppTheme.captionFont)
                        .foregroundColor(item.typeColor)
                }
            }
            
            Spacer()
            
            if item.type == .chore {
                Button(action: {
                    // Toggle completion
                }) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(item.isCompleted ? AppTheme.successColor : AppTheme.textTertiary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: AppTheme.cardShadow, radius: AppTheme.shadowRadius, x: 0, y: 2)
    }
    
    private func activityRow(_ activity: RoommateActivity) -> some View {
        HStack(spacing: 16) {
            // Avatar or icon
            ZStack {
                Circle()
                    .fill(AppTheme.primaryColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Text(String(activity.userName.prefix(1)))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.primaryColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(activity.userName) \(activity.actionVerb) \(activity.itemName)")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(timeAgo(activity.timestamp))
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.textTertiary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: AppTheme.cardShadow, radius: AppTheme.shadowRadius, x: 0, y: 2)
    }
    
    // Data Models for Dashboard
    struct UpcomingItem: Identifiable {
        var id: String
        var title: String
        var dueDate: Date
        var type: UpcomingItemType
        var isCompleted: Bool
        var icon: String
        
        var typeColor: Color {
            switch type {
            case .chore:
                return AppTheme.primaryColor
            case .event:
                return AppTheme.accentColor
            }
        }
    }
    
    enum UpcomingItemType: String {
        case chore = "Chore"
        case event = "Event"
    }
    
    // Helper Functions
    private func loadData() {
        viewModel.fetchHousehold(householdId: householdId)
        viewModel.fetchChores(householdId: householdId)
        viewModel.fetchEvents(householdId: householdId)
        viewModel.fetchHouseholdMembers(householdId: householdId)
        
        // Load some sample activity data
        // In a real app, this would come from Firebase
        let sampleActivity = [
            RoommateActivity(
                id: "1",
                userName: "Alex",
                actionVerb: "completed",
                itemName: "Take out trash",
                itemType: "chore",
                timestamp: Date().addingTimeInterval(-3600)
            ),
            RoommateActivity(
                id: "2",
                userName: "Jamie",
                actionVerb: "added",
                itemName: "Milk",
                itemType: "grocery",
                timestamp: Date().addingTimeInterval(-7200)
            )
        ]
        
        // In a real app, assign to viewModel.recentActivity
        DispatchQueue.main.async {
            viewModel.recentActivity = sampleActivity
        }
    }
    
    private var upcomingItems: [UpcomingItem] {
        var items: [UpcomingItem] = []
        
        // Add chores
        for chore in viewModel.chores {
            if let id = chore.id {
                items.append(UpcomingItem(
                    id: id,
                    title: chore.title,
                    dueDate: chore.dueDate,
                    type: .chore,
                    isCompleted: chore.isCompleted,
                    icon: "checkmark.circle"
                ))
            }
        }
        
        // Add events
        for event in viewModel.events {
            if let id = event.id, event.startDate > Date() {
                items.append(UpcomingItem(
                    id: id,
                    title: event.title,
                    dueDate: event.startDate,
                    type: .event,
                    isCompleted: false,
                    icon: "calendar"
                ))
            }
        }
        
        // Sort by due date
        return items.sorted { $0.dueDate < $1.dueDate }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    private func dueDateColor(_ date: Date) -> Color {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        
        if days < 0 {
            return AppTheme.errorColor // Overdue
        } else if days == 0 {
            return AppTheme.accentColor // Today
        } else {
            return AppTheme.textSecondary // Later
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
