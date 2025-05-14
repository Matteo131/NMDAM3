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
            LazyVStack(spacing: AppTheme.spacing) {
                // Household header
                householdHeaderSection
                
                // Quick action buttons
                quickActionSection
                
                
                // Upcoming tasks
                upcomingTasksSection
                
                // Recent activity
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
    
    // MARK: - Computed Properties
    
    private var pendingItemsCount: Int {
        let overdueChores = viewModel.chores.filter { !$0.isCompleted && $0.dueDate < Date() }.count
        let unsettledExpenses = viewModel.expenses.filter { !$0.settled.values.allSatisfy { $0 } }.count
        return overdueChores + unsettledExpenses
    }
    
    private var urgentChoresCount: Int {
        viewModel.chores.filter { !$0.isCompleted && Calendar.current.isDateInToday($0.dueDate) }.count
    }
    
    private var todayChoresCount: Int {
        viewModel.chores.filter { !$0.isCompleted && Calendar.current.isDateInToday($0.dueDate) }.count
    }
    
    private var groceryItemsCount: Int {
        viewModel.groceryItems.filter { !$0.isCompleted }.count
    }
    
    private var yourBalance: Double {
        guard let userId = Auth.auth().currentUser?.uid else { return 0 }
        
        var balance: Double = 0
        
        for expense in viewModel.expenses {
            if expense.paidBy == userId {
                // Add what others owe you
                for person in expense.splitAmong where person != userId {
                    if let settled = expense.settled[person], !settled {
                        balance += expense.amountPerPerson
                        
                        // MARK: - Header Section
                        
                        private var householdHeaderSection: some View {
                            Group {
                                if let household = viewModel.household {
                                    householdHeaderContent(household: household)
                                } else {
                                    loadingPlaceholder
                                }
                            }
                        }
                        
                        private func householdHeaderContent(household: Household) -> some View {
                            VStack(spacing: 16) {
                                // Main header
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Welcome back!")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppTheme.textSecondary)
                                        
                                        Text(household.name)
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    
                                    Spacer()
                                    
                                    profileButton
                                }
                                
                                // Key metrics row
                                if hasMetrics {
                                    metricsRow
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(AppTheme.cornerRadius)
                            .shadow(color: AppTheme.cardShadow, radius: AppTheme.shadowRadius, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                        
                        private var profileButton: some View {
                            NavigationLink(destination: ProfileView()) {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.primaryColor.opacity(0.1))
                                        .frame(width: 48, height: 48)
                                    
                                    profileContent
                                    
                                    if pendingItemsCount > 0 {
                                        notificationBadge
                                    }
                                }
                            }
                        }
                        
                        private var profileContent: some View {
                            Group {
                                if let displayName = Auth.auth().currentUser?.displayName,
                                   let firstLetter = displayName.first {
                                    Text(String(firstLetter))
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(AppTheme.primaryColor)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(AppTheme.primaryColor)
                                }
                            }
                        }
                        
                        private var notificationBadge: some View {
                            Circle()
                                .fill(AppTheme.errorColor)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Text("\(min(pendingItemsCount, 9))")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 18, y: -18)
                        }
                        
                        private var hasMetrics: Bool {
                            !viewModel.chores.isEmpty || !viewModel.expenses.isEmpty
                        }
                        
                        private var metricsRow: some View {
                            HStack(spacing: 20) {
                                if urgentChoresCount > 0 {
                                    MetricBadge(
                                        icon: "exclamationmark.circle.fill",
                                        title: "\(urgentChoresCount) due today",
                                        color: AppTheme.errorColor
                                    )
                                }
                                
                                if yourBalance != 0 {
                                    balanceMetricBadge
                                }
                                
                                Spacer()
                            }
                        }
                        
                        private var balanceMetricBadge: some View {
                            MetricBadge(
                                icon: yourBalance > 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill",
                                title: balanceText,
                                color: yourBalance > 0 ? AppTheme.successColor : AppTheme.warningColor
                            )
                        }
                        
                        private var balanceText: String {
                            let absBalance = abs(yourBalance)
                            if yourBalance > 0 {
                                return "£\(String(format: "%.0f", absBalance)) owed to you"
                            } else {
                                return "You owe £\(String(format: "%.0f", absBalance))"
                            }
                        }
                        
                        private var loadingPlaceholder: some View {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 120)
                                .padding(.horizontal)
                        }
                        
                        // MARK: - Quick Actions Section
                        
                        private var quickActionSection: some View {
                            VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                                sectionTitle("Quick Actions")
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: AppTheme.spacing) {
                                        quickActionButton(
                                            title: todayChoresCount > 0 ? "Today's Chores" : "Add Chore",
                                            subtitle: todayChoresCount > 0 ? "\(todayChoresCount) pending" : nil,
                                            icon: "checkmark.circle.fill",
                                            color: AppTheme.primaryColor
                                        ) {
                                            showingAddChore = true
                                        }
                                        
                                        quickActionButton(
                                            title: isWeekend ? "Grocery Run" : "Add Grocery",
                                            subtitle: isWeekend ? "\(groceryItemsCount) items" : nil,
                                            icon: "cart.fill",
                                            color: AppTheme.secondaryColor
                                        ) {
                                            showingAddGrocery = true
                                        }
                                        
                                        quickActionButton(
                                            title: "Add Event",
                                            subtitle: nil,
                                            icon: "calendar",
                                            color: AppTheme.accentColor
                                        ) {
                                            showingAddEvent = true
                                        }
                                        
                                        quickActionButton(
                                            title: "Add Expense",
                                            subtitle: nil,
                                            icon: "dollarsign.circle.fill",
                                            color: AppTheme.errorColor
                                        ) {
                                            showingAddExpense = true
                                            >>>>>>> 97a798c (Initial commit)
                                        }
                                    }
                                } else if expense.splitAmong.contains(userId) {
                                    // Subtract what you owe
                                    if let settled = expense.settled[userId], !settled {
                                        balance -= expense.amountPerPerson
                                    }
                                }
                            }
                            
                            return balance
                        }
                        
                        private var isWeekend: Bool {
                            let weekday = Calendar.current.component(.weekday, from: Date())
                            return weekday == 1 || weekday == 7
                        }
                        
                        // MARK: - Upcoming Tasks Section
                        
                        private var upcomingTasksSection: some View {
                            VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                                HStack {
                                    sectionTitle("Upcoming Tasks")
                                    
                                    Spacer()
                                    
                                    NavigationLink(destination: ChoresView(viewModel: viewModel, householdId: householdId)) {
                                        Text("See All")
                                            .font(AppTheme.captionFont)
                                            .foregroundColor(AppTheme.primaryColor)
                                    }
                                }
                                .padding(.horizontal)
                                
                                upcomingTasksContent
                            }
                        }
                        
                        private var upcomingTasksContent: some View {
                            Group {
                                if upcomingTasks.isEmpty {
                                    emptyStateCard(
                                        message: "No upcoming tasks. Add some to get started!",
                                        icon: "checkmark.circle"
                                    )
                                } else {
                                    VStack(spacing: 8) {
                                        ForEach(Array(upcomingTasks.prefix(3))) { task in
                                            upcomingTaskRow(task)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // MARK: - Recent Activity Section
                        
                        private var recentActivitySection: some View {
                            VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                                sectionTitle("Recent Activity")
                                    .padding(.horizontal)
                                
                                recentActivityContent
                            }
                        }
                        
                        private var recentActivityContent: some View {
                            Group {
                                if viewModel.recentActivity.isEmpty {
                                    emptyStateCard(
                                        message: "No recent activity. Your household events will appear here.",
                                        icon: "person.2.fill"
                                    )
                                } else {
                                    VStack(spacing: 8) {
                                        ForEach(Array(viewModel.recentActivity.prefix(3))) { activity in
                                            activityRow(activity)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // MARK: - Helper Views
                        
                        private func sectionTitle(_ title: String) -> some View {
                            Text(title)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        
                        private func quickActionButton(
                            title: String,
                            subtitle: String?,
                            icon: String,
                            color: Color,
                            action: @escaping () -> Void
                        ) -> some View {
                            Button(action: action) {
                                VStack(spacing: subtitle != nil ? 6 : 8) {
                                    Image(systemName: icon)
                                        .font(.system(size: subtitle != nil ? 20 : 24, weight: .medium))
                                        .foregroundColor(color)
                                    
                                    Text(title)
                                        .font(.system(size: subtitle != nil ? 13 : 13, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .lineLimit(1)
                                    
                                    if let subtitle = subtitle {
                                        Text(subtitle)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(color)
                                            .lineLimit(1)
                                    }
                                }
                                .frame(width: subtitle != nil ? 110 : 100, height: subtitle != nil ? 90 : 80)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(subtitle != nil ? color.opacity(0.2) : Color.clear, lineWidth: 1.5)
                                        )
                                )
                                .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        <<<<<<< HEAD
                        private func smartActionButton(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
                            Button(action: action) {
                                VStack(spacing: 6) {
                                    Image(systemName: icon)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(color)
                                    
                                    Text(title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .lineLimit(1)
                                    
                                    Text(subtitle)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(color)
                                        .lineLimit(1)
                                }
                                .frame(width: 110, height: 90)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(color.opacity(0.2), lineWidth: 1.5)
                                        )
                                )
                                .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        private func emptyStateView(message: String, icon: String) -> some View {
                            
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
                                .padding(.horizontal)
                            }
                            
                            private func upcomingTaskRow(_ task: UpcomingTask) -> some View {
                                HStack(spacing: 16) {
                                    Image(systemName: task.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(task.typeColor)
                                        .frame(width: 24, height: 24)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(task.title)
                                            .font(AppTheme.bodyFont)
                                            .foregroundColor(AppTheme.textPrimary)
                                            .lineLimit(1)
                                        
                                        taskMetadata(task)
                                    }
                                    
                                    Spacer()
                                    
                                    if task.type == .chore {
                                        toggleButton(task)
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(AppTheme.cornerRadius)
                                .shadow(color: AppTheme.cardShadow, radius: AppTheme.shadowRadius, x: 0, y: 2)
                            }
                            
                            private func taskMetadata(_ task: UpcomingTask) -> some View {
                                HStack {
                                    Text(formatDate(task.dueDate))
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(dueDateColor(task.dueDate))
                                    
                                    Text("•")
                                        .foregroundColor(AppTheme.textTertiary)
                                    
                                    Text(task.assignedTo ?? task.type.rawValue)
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(AppTheme.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                            
                            private func toggleButton(_ task: UpcomingTask) -> some View {
                                Button(action: {
                                    viewModel.toggleChoreCompletion(
                                        householdId: householdId,
                                        choreId: task.id,
                                        isCompleted: !task.isCompleted
                                    )
                                }) {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(task.isCompleted ? AppTheme.successColor : AppTheme.textTertiary)
                                }
                            }
                            
                            private func activityRow(_ activity: RoommateActivity) -> some View {
                                HStack(spacing: 16) {
                                    // Avatar
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
                            
                            
                            
                            private var pendingItemsCount: Int {
                                let overdueChores = viewModel.chores.filter { !$0.isCompleted && $0.dueDate < Date() }.count
                                let unsettledExpenses = viewModel.expenses.filter { !$0.settled.values.allSatisfy { $0 } }.count
                                return overdueChores + unsettledExpenses
                            }
                            
                            private var urgentChoresCount: Int {
                                viewModel.chores.filter { !$0.isCompleted && Calendar.current.isDateInToday($0.dueDate) }.count
                            }
                            
                            private var todayChoresCount: Int {
                                viewModel.chores.filter { !$0.isCompleted && Calendar.current.isDateInToday($0.dueDate) }.count
                            }
                            
                            private var groceryItemsCount: Int {
                                viewModel.groceryItems.filter { !$0.isCompleted }.count
                            }
                            
                            private var yourBalance: Double {
                                guard let userId = Auth.auth().currentUser?.uid else { return 0 }
                                
                                var balance: Double = 0
                                
                                for expense in viewModel.expenses {
                                    if expense.paidBy == userId {
                                        // Add what others owe you
                                        for person in expense.splitAmong where person != userId {
                                            if let settled = expense.settled[person], !settled {
                                                balance += expense.amountPerPerson
                                            }
                                        }
                                    } else if expense.splitAmong.contains(userId) {
                                        // Subtract what you owe
                                        if let settled = expense.settled[userId], !settled {
                                            balance -= expense.amountPerPerson
                                        }
                                    }
                                }
                                
                                return balance
                            }
                            
                            private var isWeekend: Bool {
                                let weekday = Calendar.current.component(.weekday, from: Date())
                                return weekday == 1 || weekday == 7
                            }
                            
                            private var upcomingTasks: [UpcomingTask] {
                                var tasks: [UpcomingTask] = []
                                
                                // Add chores
                                for chore in viewModel.chores {
                                    if let choreId = chore.id, !choreId.isEmpty {
                                        tasks.append(UpcomingTask(
                                            id: choreId,
                                            title: chore.title,
                                            dueDate: chore.dueDate,
                                            type: .chore,
                                            isCompleted: chore.isCompleted,
                                            icon: "checkmark.circle",
                                            assignedTo: chore.assignedTo
                                        ))
                                    }
                                }
                                
                                // Add events
                                for event in viewModel.events {
                                    if let eventId = event.id, !eventId.isEmpty, event.startDate > Date() {
                                        tasks.append(UpcomingTask(
                                            id: eventId,
                                            title: event.title,
                                            dueDate: event.startDate,
                                            type: .event,
                                            isCompleted: false,
                                            icon: "calendar",
                                            assignedTo: nil
                                        ))
                                    }
                                }
                                
                                // Sort by due date
                                return tasks.sorted { $0.dueDate < $1.dueDate }
                            }
                            
                            // MARK: - Helper Methods
                            
                            
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
                        
                        
                        struct UpcomingTask: Identifiable {
                            var id: String
                            var title: String
                            var dueDate: Date
                            var type: UpcomingTaskType
                            var isCompleted: Bool
                            var icon: String
                            var assignedTo: String?
                            
                            var typeColor: Color {
                                switch type {
                                case .chore:
                                    return AppTheme.primaryColor
                                case .event:
                                    return AppTheme.accentColor
                                }
                            }
                        }
                        
                        enum UpcomingTaskType: String {
                            case chore = "Chore"
                            case event = "Event"
                        }
                        
                        
                        
                        struct MetricBadge: View {
                            let icon: String
                            let title: String
                            let color: Color
                            
                            var body: some View {
                                HStack(spacing: 6) {
                                    Image(systemName: icon)
                                        .font(.system(size: 14))
                                        .foregroundColor(color)
                                    
                                    Text(title)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(color)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(color.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
    }
}

