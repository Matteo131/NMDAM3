import SwiftUI
import Firebase
import FirebaseAuth

struct DashboardView: View {
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    @State private var showingAddChore = false
    @State private var showingAddGrocery = false
    @State private var showingAddEvent = false
    @State private var showingAddExpense = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacing) {
                // Household header
                // Add this to the top section of DashboardView where you have the household header
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
                        
                        // Add Profile Navigation Link
                        NavigationLink(destination: ProfileView()) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.primaryColor.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                
                                Text(String(Auth.auth().currentUser?.displayName?.prefix(1) ?? "U"))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryColor)
                            }
                        }
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
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadData()
        }
        .sheet(isPresented: $showingAddChore) {
            AddChoreView(viewModel: viewModel, householdId: householdId)
        }
        .sheet(isPresented: $showingAddGrocery) {
            AddGroceryItemView(viewModel: viewModel, householdId: householdId)
        }
        .sheet(isPresented: $showingAddEvent) {
            AddEventView(viewModel: viewModel, householdId: householdId, initialDate: Date())
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(viewModel: viewModel, householdId: householdId)
        }
    }
    
    private var quickActionButtons: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            Text("Quick Actions")
                .font(AppTheme.headlineFont)
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.spacing) {
                    actionButton(
                        title: "Add Chore",
                        icon: "checkmark.circle.fill",
                        color: AppTheme.primaryColor
                    ) {
                        showingAddChore = true
                    }
                    
                    actionButton(
                        title: "Add Grocery",
                        icon: "cart.fill",
                        color: AppTheme.secondaryColor
                    ) {
                        showingAddGrocery = true
                    }
                    
                    actionButton(
                        title: "Add Event",
                        icon: "calendar",
                        color: AppTheme.accentColor
                    ) {
                        showingAddEvent = true
                    }
                    
                    actionButton(
                        title: "Add Expense",
                        icon: "dollarsign.circle.fill",
                        color: AppTheme.errorColor
                    ) {
                        showingAddExpense = true
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var upcomingTasksSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            HStack {
                Text("Upcoming Tasks")
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: ChoresView(viewModel: viewModel, householdId: householdId)) {
                    Text("See All")
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.primaryColor)
                }
            }
            .padding(.horizontal)
            
            if viewModel.chores.filter({ !$0.isCompleted }).isEmpty {
                emptyStateView(
                    message: "No upcoming tasks. Add some to get started!",
                    icon: "checkmark.circle"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.chores.filter { !$0.isCompleted }.prefix(3)) { chore in
                        upcomingTaskRow(chore)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            Text("Recent Activity")
                .font(AppTheme.headlineFont)
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal)
            
            if viewModel.recentActivity.isEmpty {
                emptyStateView(
                    message: "No recent activity. Your household events will appear here.",
                    icon: "person.2.fill"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.recentActivity.prefix(3)) { activity in
                        activityRow(activity)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // Helper Views
    
    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
    }
    
    private func emptyStateView(message: String, icon: String) -> some View {
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
        .padding(.horizontal)
    }
    
    private func upcomingTaskRow(_ chore: Chore) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 20))
                .foregroundColor(AppTheme.primaryColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chore.title)
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                
                HStack {
                    Text(formatDate(chore.dueDate))
                        .font(AppTheme.captionFont)
                        .foregroundColor(dueDateColor(chore.dueDate))
                    
                    Text("•")
                        .foregroundColor(AppTheme.textTertiary)
                    
                    Text("Assigned to: \(chore.assignedTo)")
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Button(action: {
                // Toggle completion
                if let id = chore.id {
                    viewModel.toggleChoreCompletion(
                        householdId: householdId,
                        choreId: id,
                        isCompleted: !chore.isCompleted
                    )
                }
            }) {
                Image(systemName: chore.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(chore.isCompleted ? AppTheme.successColor : AppTheme.textTertiary)
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
    
    // Helper Functions
    private func loadData() {
        viewModel.fetchHousehold(householdId: householdId)
        viewModel.fetchChores(householdId: householdId)
        viewModel.fetchGroceryItems(householdId: householdId)
        viewModel.fetchEvents(householdId: householdId)
        viewModel.fetchHouseholdMembers(householdId: householdId)
        viewModel.fetchRecentActivity(householdId: householdId)
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
