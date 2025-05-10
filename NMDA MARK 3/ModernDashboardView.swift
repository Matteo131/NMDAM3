import SwiftUI
import Firebase
import FirebaseAuth

struct ModernDashboardView: View {
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    @State private var userStats = UserStats()
    @State private var activityFeed: [ActivityFeedItem] = []
    @State private var showingAllActivity = false
    @State private var isFirstLoad = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacing) {
                // Top header with user level and points
                userHeader
                
                // Quick stats cards
                quickStats
                
                // Upcoming items
                upcomingItems
                
                // Activity feed
                activityFeedView
            }
            .padding(.bottom, 20)
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarHidden(true)
        .onAppear {
            if isFirstLoad {
                loadUserData()
                loadActivityFeed()
                checkForAchievements()
                isFirstLoad = false
            }
        }
    }
    
    // User header with level progress
    private var userHeader: some View {
        ZStack {
            // Background card with gradient
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            userStats.currentLevel.colorValue,
                            userStats.currentLevel.colorValue.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Pattern overlay
                    Image(systemName: "circle.hexagongrid.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .foregroundColor(Color.white.opacity(0.1))
                        .blendMode(.screen)
                )
            
            // Content
            VStack(spacing: AppTheme.spacing) {
                // User info
                HStack {
                    // User avatar
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        if let displayName = Auth.auth().currentUser?.displayName, !displayName.isEmpty {
                            Text(String(displayName.prefix(1)))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back!")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(Auth.auth().currentUser?.displayName ?? "Roommate")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Level badge
                    VStack(spacing: 2) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: userStats.currentLevel.icon)
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        
                        Text("Level \(userStats.currentLevel.id)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }
                }
                
                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)
                
                // Level progress
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(userStats.currentLevel.name)")
                            .font(.callout.bold())
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if let nextLevel = userStats.nextLevel {
                            Text("\(userStats.points)/\(nextLevel.requiredPoints) XP")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            Text("Max Level")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 8)
                            
                            // Progress
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: geometry.size.width * userStats.progressToNextLevel, height: 8)
                                .animation(.spring(), value: userStats.progressToNextLevel)
                        }
                    }
                    .frame(height: 8)
                    
                    if let nextLevel = userStats.nextLevel {
                        Text("Next: \(nextLevel.name)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .padding()
        }
        .frame(height: 200)
        .shadow(color: userStats.currentLevel.colorValue.opacity(0.3), radius: 15, x: 0, y: 5)
        .padding(.horizontal)
    }
    
    // Quick stats cards (chores, groceries, expenses)
    private var quickStats: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Chores card
                statCard(
                    title: "Chores",
                    value: "\(userStats.choresDone)",
                    icon: "checkmark.circle.fill",
                    color: AppTheme.primaryColor,
                    destination: AnyView(ChoresView(viewModel: viewModel, householdId: householdId))
                )
                
                // Grocery card
                statCard(
                    title: "Grocery Items",
                    value: "\(userStats.groceryItemsBought)",
                    icon: "cart.fill",
                    color: AppTheme.secondaryColor,
                    destination: AnyView(EnhancedGroceryView(viewModel: viewModel, householdId: householdId))
                )
                
                // Expenses card
                statCard(
                    title: "Expenses Paid",
                    value: "$\(String(format: "%.2f", userStats.expensesPaid))",
                    icon: "dollarsign.circle.fill",
                    color: AppTheme.accentColor,
                    destination: AnyView(ExpensesView(viewModel: viewModel, householdId: householdId))
                )
                
                // Streak card
                statCard(
                    title: "Day Streak",
                    value: "\(userStats.streakDays)",
                    icon: "flame.fill",
                    color: AppTheme.dangerColor,
                    destination: AnyView(Text("Streaks"))
                )
            }
            .padding(.horizontal)
        }
    }
    
    // Reusable stat card component
    private func statCard<Destination: View>(title: String, value: String, icon: String, color: Color, destination: Destination) -> some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                // Title
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                
                // Value
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(AppTheme.textPrimary)
            }
            .frame(width: 140, height: 130)
            .padding()
            .background(Color.white)
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Upcoming items section
    private var upcomingItems: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            HStack {
                Text("Upcoming Tasks")
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal)
            
            if viewModel.chores.isEmpty && viewModel.events.isEmpty {
                emptyUpcomingState
            } else {
                // Today's tasks
                VStack(spacing: 12) {
                    ForEach(upcomingChoresAndEvents.prefix(3)) { item in
                        upcomingItemRow(item)
                    }
                    
                    if upcomingChoresAndEvents.count > 3 {
                        Button(action: {
                            // Navigate to all tasks view
                        }) {
                            Text("View All \(upcomingChoresAndEvents.count) Tasks")
                                .font(AppTheme.subheadlineFont)
                                .foregroundColor(AppTheme.primaryColor)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(AppTheme.primaryColor.opacity(0.1))
                                .cornerRadius(AppTheme.cornerRadius)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(AppTheme.cornerRadius)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
            }
        }
    }
    
    // Empty state for upcoming tasks
    private var emptyUpcomingState: some View {
        VStack(spacing: 16) {
            // Illustration
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.primaryColor.opacity(0.3))
            
            Text("You're all caught up!")
                .font(AppTheme.subheadlineFont)
                .foregroundColor(AppTheme.textSecondary)
            
            Text("Add some tasks to get started")
                .font(AppTheme.captionFont)
                .foregroundColor(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
    
    // Activity feed section
    private var activityFeedView: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            HStack {
                Text("Roommate Activity")
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                if activityFeed.count > 3 && !showingAllActivity {
                    Button("See All") {
                        showingAllActivity = true
                    }
                    .font(AppTheme.captionFont.bold())
                    .foregroundColor(AppTheme.primaryColor)
                }
            }
            .padding(.horizontal)
            
            if activityFeed.isEmpty {
                emptyActivityFeedState
            } else {
                VStack(spacing: 0) {
                    let feedItems = showingAllActivity ? activityFeed : Array(activityFeed.prefix(3))
                    
                    ForEach(feedItems) { activity in
                        activityRow(activity)
                        
                        if activity.id != feedItems.last?.id {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                    
                    if showingAllActivity && activityFeed.count > 3 {
                        Button(action: {
                            showingAllActivity = false
                        }) {
                            Text("Show Less")
                                .font(AppTheme.captionFont.bold())
                                .foregroundColor(AppTheme.primaryColor)
                                .padding()
                        }
                    }
                }
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(AppTheme.cornerRadius)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
            }
        }
    }
    
    // Empty state for activity feed
    private var emptyActivityFeedState: some View {
        VStack(spacing: 16) {
            // Illustration
            Image(systemName: "person.2.fill")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.secondaryColor.opacity(0.3))
            
            Text("No recent activity")
                .font(AppTheme.subheadlineFont)
                .foregroundColor(AppTheme.textSecondary)
            
            Text("Activity from you and your roommates will appear here")
                .font(AppTheme.captionFont)
                .foregroundColor(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
    
    // Load user data and stats
    private func loadUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        UserStats.fetch(for: userId, in: householdId) { stats in
            if let stats = stats {
                self.userStats = stats
            }
        }
    }
    
    // Load activity feed
    private func loadActivityFeed() {
        // This would typically come from Firestore
        // For now, we'll use sample data
        self.activityFeed = [
            ActivityFeedItem(
                id: "1",
                userId: "user1",
                userName: "Roommate 1",
                actionType: .complete,
                objectType: .chore,
                objectId: "chore1",
                objectName: "Take out trash",
                points: 10,
                timestamp: Date().addingTimeInterval(-1800),
                isHighlighted: false
            ),
            ActivityFeedItem(
                id: "2",
                userId: "user2",
                userName: "Roommate 2",
                actionType: .add,
                objectType: .grocery,
                objectId: "grocery1",
                objectName: "Chicken",
                points: 10,
                timestamp: Date().addingTimeInterval(-1200),
                isHighlighted: true
            ),
        ]
    }
    // Activity row component
    private func activityRow(_ activity: ActivityFeedItem) -> some View {
        HStack(spacing: 16) {
            // User avatar
            ZStack {
                Circle()
                    .fill(activity.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: activity.icon)
                    .font(.system(size: 18))
                    .foregroundColor(activity.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Action text with highlighted name
                HStack(spacing: 4) {
                    Text(activity.userName)
                        .fontWeight(.semibold) +
                    Text(" \(activity.description)")
                }
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.textPrimary)
                
                // Time and points
                HStack {
                    Text(timeAgo(activity.timestamp))
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.textTertiary)
                    
                    if activity.points > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            
                            Text("+\(activity.points) XP")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(Color.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(activity.isHighlighted ? activity.color.opacity(0.05) : Color.clear)
    }
    
    // Format time ago
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // Upcoming item models
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
        case chore, event
    }
    
    // Computed property for upcoming chores and events
    private var upcomingChoresAndEvents: [UpcomingItem] {
        var items: [UpcomingItem] = []
        
        // Add chores
        for chore in viewModel.chores.filter({ !$0.isCompleted }) {
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
    
    // Upcoming item row component
    private func upcomingItemRow(_ item: UpcomingItem) -> some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(item.typeColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: item.icon)
                    .font(.system(size: 18))
                    .foregroundColor(item.typeColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(AppTheme.bodyFont.weight(.medium))
                    .foregroundColor(AppTheme.textPrimary)
                
                HStack(spacing: 6) {
                    // Due date
                    Label(
                        title: {
                            Text(formatDueDate(item.dueDate))
                                .font(AppTheme.captionFont)
                                .foregroundColor(dueDateColor(item.dueDate))
                        },
                        icon: {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                                .foregroundColor(dueDateColor(item.dueDate))
                        }
                    )
                    
                    // Type badge
                    Text(item.type.rawValue.capitalized)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(item.typeColor.opacity(0.1))
                        .foregroundColor(item.typeColor)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Priority indicator or action button
            if item.type == .chore {
                Button(action: {
                    // Mark as complete
                }) {
                    Image(systemName: "circle")
                        .font(.system(size: 22))
                        .foregroundColor(item.typeColor)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    // Format due date
    private func formatDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today, \(formatTime(date))"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow, \(formatTime(date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: date)
        }
    }
    
    // Format time
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    // Due date color
    private func dueDateColor(_ date: Date) -> Color {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        
        if days < 0 {
            return AppTheme.dangerColor // Overdue
        } else if days == 0 {
            return AppTheme.warningColor // Today
        } else if days <= 2 {
            return AppTheme.accentColor // Soon
        } else {
            return AppTheme.textSecondary // Later
        }
    }
    
    // Check for achievements
    private func checkForAchievements() {
        // This would typically be a more complex system that checks various conditions
        // For now, we'll simulate the achievement system
        
        // Get user ID
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Sample achievements to check
        let achievements = [
            Achievement(
                id: "first_chore",
                title: "First Chore",
                description: "Complete your first chore",
                icon: "checkmark.circle.fill",
                points: 10,
                category: .chores,
                isUnlocked: userStats.choresDone > 0,
                unlockedAt: userStats.choresDone > 0 ? Date() : nil,
                progress: userStats.choresDone > 0 ? 1.0 : 0.0
            ),
            Achievement(
                id: "grocery_master",
                title: "Shopping Pro",
                description: "Buy 5 grocery items",
                icon: "cart.fill",
                points: 25,
                category: .grocery,
                isUnlocked: userStats.groceryItemsBought >= 5,
                unlockedAt: userStats.groceryItemsBought >= 5 ? Date() : nil,
                progress: min(Double(userStats.groceryItemsBought) / 5.0, 1.0)
            ),
            Achievement(
                id: "expense_tracker",
                title: "Bill Splitter",
                description: "Pay your first expense",
                icon: "dollarsign.circle.fill",
                points: 15,
                category: .expenses,
                isUnlocked: userStats.expensesPaid > 0,
                unlockedAt: userStats.expensesPaid > 0 ? Date() : nil,
                progress: userStats.expensesPaid > 0 ? 1.0 : 0.0
            ),
            Achievement(
                id: "streak_3",
                title: "On Fire",
                description: "Login for 3 days in a row",
                icon: "flame.fill",
                points: 30,
                category: .special,
                isUnlocked: userStats.streakDays >= 3,
                unlockedAt: userStats.streakDays >= 3 ? Date() : nil,
                progress: min(Double(userStats.streakDays) / 3.0, 1.0)
            )
        ]
        
        // Check for newly unlocked achievements
        for achievement in achievements {
            if achievement.isUnlocked && !userStats.achievements.contains(achievement.id) {
                // Add achievement ID to user stats
                var updatedStats = userStats
                updatedStats.achievements.append(achievement.id)
                updatedStats.addPoints(achievement.points)
                
                // Save updated stats
                updatedStats.save(for: userId, in: householdId)
                
                // Update local state
                userStats = updatedStats
                
                // Show achievement alert (in a real app)
                print("Achievement unlocked: \(achievement.title)")
            }
        }
    }
    
    struct AchievementsView: View {
        let householdId: String
        @State private var achievements: [Achievement] = []
        @State private var userStats = UserStats()
        @State private var selectedCategory: AchievementCategory? = nil
        
        var body: some View {
            ScrollView {
                VStack(spacing: AppTheme.spacing) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Achievements")
                            .font(AppTheme.titleFont)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text("\(userStats.achievements.count) of \(achievements.count) unlocked")
                            .font(AppTheme.subheadlineFont)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding()
                    
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            categoryButton(nil, "All")
                            
                            ForEach(AchievementCategory.allCases, id: \.self) { category in
                                categoryButton(category, category.rawValue)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Achievements grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredAchievements) { achievement in
                            achievementCard(achievement)
                        }
                    }
                    .padding()
                }
            }
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Achievements")
            .onAppear(perform: loadData)
        }
        
        private var filteredAchievements: [Achievement] {
            if let category = selectedCategory {
                return achievements.filter { $0.category == category }
            } else {
                return achievements
            }
        }
        
        private func categoryButton(_ category: AchievementCategory?, _ title: String) -> some View {
            Button(action: {
                withAnimation {
                    selectedCategory = category
                }
            }) {
                Text(title)
                    .font(AppTheme.subheadlineFont)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(selectedCategory == category ?
                                  (category?.color ?? AppTheme.primaryColor) :
                                    Color.white)
                    )
                    .foregroundColor(selectedCategory == category ?
                        .white :
                                        (category?.color ?? AppTheme.primaryColor))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
        }
        
        private func achievementCard(_ achievement: Achievement) -> some View {
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(achievement.isUnlocked ?
                              achievement.color.opacity(0.15) :
                                Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    if achievement.isUnlocked {
                        Image(systemName: achievement.icon)
                            .font(.system(size: 30))
                            .foregroundColor(achievement.color)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.gray.opacity(0.5))
                    }
                }
                
                // Title and description
                VStack(spacing: 4) {
                    Text(achievement.title)
                        .font(AppTheme.subheadlineFont)
                        .foregroundColor(achievement.isUnlocked ?
                                         AppTheme.textPrimary :
                                            AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Text(achievement.description)
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                
                // Points or progress
                if achievement.isUnlocked {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                        
                        Text("+\(achievement.points) XP")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(Color.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    // Progress bar
                    VStack(spacing: 4) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 6)
                                
                                // Progress
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(achievement.color.opacity(0.5))
                                    .frame(width: geometry.size.width * achievement.progress, height: 6)
                            }
                        }
                        .frame(height: 6)
                        
                        Text("\(Int(achievement.progress * 100))%")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
            }
            .padding()
            .frame(height: 200)
            .background(Color.white)
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        }
        
        private func loadData() {
            // Load user stats
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            UserStats.fetch(for: userId, in: householdId) { stats in
                if let stats = stats {
                    self.userStats = stats
                }
            }
            
            // Load achievements (would typically come from Firestore)
            self.achievements = [
                Achievement(
                    id: "first_chore",
                    title: "First Chore",
                    description: "Complete your first chore",
                    icon: "checkmark.circle.fill",
                    points: 10,
                    category: .chores,
                    isUnlocked: userStats.choresDone > 0,
                    unlockedAt: userStats.choresDone > 0 ? Date() : nil,
                    progress: userStats.choresDone > 0 ? 1.0 : 0.0
                ),
                Achievement(
                    id: "chore_5",
                    title: "Chore Master",
                    description: "Complete 5 chores",
                    icon: "checkmark.circle.fill",
                    points: 25,
                    category: .chores,
                    isUnlocked: userStats.choresDone >= 5,
                    unlockedAt: userStats.choresDone >= 5 ? Date() : nil,
                    progress: min(Double(userStats.choresDone) / 5.0, 1.0)
                ),
                Achievement(
                    id: "chore_20",
                    title: "Cleaning Legend",
                    description: "Complete 20 chores",
                    icon: "sparkles",
                    points: 50,
                    category: .chores,
                    isUnlocked: userStats.choresDone >= 20,
                    unlockedAt: userStats.choresDone >= 20 ? Date() : nil,
                    progress: min(Double(userStats.choresDone) / 20.0, 1.0)
                ),
                Achievement(
                    id: "grocery_1",
                    title: "First Purchase",
                    description: "Buy your first grocery item",
                    icon: "cart.fill",
                    points: 10,
                    category: .grocery,
                    isUnlocked: userStats.groceryItemsBought > 0,
                    unlockedAt: userStats.groceryItemsBought > 0 ? Date() : nil,
                    progress: userStats.groceryItemsBought > 0 ? 1.0 : 0.0
                ),
                Achievement(
                    id: "grocery_master",
                    title: "Shopping Pro",
                    description: "Buy 5 grocery items",
                    icon: "cart.fill",
                    points: 25,
                    category: .grocery,
                    isUnlocked: userStats.groceryItemsBought >= 5,
                    unlockedAt: userStats.groceryItemsBought >= 5 ? Date() : nil,
                    progress: min(Double(userStats.groceryItemsBought) / 5.0, 1.0)
                ),
                Achievement(
                    id: "expense_1",
                    title: "Bill Splitter",
                    description: "Pay your first expense",
                    icon: "dollarsign.circle.fill",
                    points: 15,
                    category: .expenses,
                    isUnlocked: userStats.expensesPaid > 0,
                    unlockedAt: userStats.expensesPaid > 0 ? Date() : nil,
                    progress: userStats.expensesPaid > 0 ? 1.0 : 0.0
                ),
                Achievement(
                    id: "expense_50",
                    title: "Big Spender",
                    description: "Pay $50 in expenses",
                    icon: "dollarsign.circle.fill",
                    points: 30,
                    category: .expenses,
                    isUnlocked: userStats.expensesPaid >= 50,
                    unlockedAt: userStats.expensesPaid >= 50 ? Date() : nil,
                    progress: min(userStats.expensesPaid / 50.0, 1.0)
                ),
                Achievement(
                    id: "streak_3",
                    title: "On Fire",
                    description: "Login for 3 days in a row",
                    icon: "flame.fill",
                    points: 30,
                    category: .special,
                    isUnlocked: userStats.streakDays >= 3,
                    unlockedAt: userStats.streakDays >= 3 ? Date() : nil,
                    progress: min(Double(userStats.streakDays) / 3.0, 1.0)
                ),
                Achievement(
                    id: "social_first",
                    title: "Team Player",
                    description: "Join your first household",
                    icon: "person.2.fill",
                    points: 20,
                    category: .social,
                    isUnlocked: true,
                    unlockedAt: Date().addingTimeInterval(-86400),
                    progress: 1.0
                )
            ]
        }
    }
}
