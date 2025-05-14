import SwiftUI
import Firebase
import FirebaseFirestore

// First, let's make Chore conform to Equatable to fix the last error
extension Chore: Equatable {
    static func == (lhs: Chore, rhs: Chore) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.description == rhs.description &&
               lhs.assignedTo == rhs.assignedTo &&
               lhs.dueDate == rhs.dueDate &&
               lhs.isCompleted == rhs.isCompleted
    }
}

struct ChoresView: View {
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    @State private var showingAddChore = false
    @State private var completedChoreIds: Set<String> = []
    @State private var animatedProgress: Double = 0
    
    // Simplified filtering logic
    private var filteredChores: [Chore] {
        viewModel.chores.filter { chore in
            // Don't show if it's completed and in the hiding set
            if chore.isCompleted && completedChoreIds.contains(chore.id ?? "") {
                return false
            }
            return true
        }
    }
    
    var body: some View {
        ZStack {
            // Set background color
            AppTheme.backgroundLight.ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView("Loading chores...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(AppTheme.cornerRadius)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            } else if filteredChores.isEmpty {
                // Empty state
                AppTheme.emptyState(
                    icon: "checkmark.circle",
                    message: "You're all caught up! No chores pending.",
                    buttonText: "Add a Chore"
                ) {
                    showingAddChore = true
                }
            } else {
                // Chores list
                VStack(spacing: 0) {
                    // Summary card with animated progress
                    VStack(spacing: 12) {
                        HStack {
                            Text("Chores")
                                .font(AppTheme.titleFont)
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Spacer()
                            
                            // Count of non-completed chores
                            let pendingCount = viewModel.chores.filter { !$0.isCompleted }.count
                            Text("\(pendingCount) pending")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppTheme.primaryColor.opacity(0.1))
                                .foregroundColor(AppTheme.primaryColor)
                                .cornerRadius(12)
                        }
                        
                        // Animated Progress bar
                        VStack(alignment: .leading, spacing: 8) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 12)
                                    
                                    // Progress with animation
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * animatedProgress, height: 12)
                                }
                            }
                            .frame(height: 12)
                            
                            HStack {
                                Text("\(Int(animatedProgress * 100))% completed")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                                
                                Spacer()
                                
                                Text("Chores reset at midnight")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                        }
                    }
                    .cardStyle()
                    .padding(.top)
                    
                    // List of chores - simplified
                    List {
                        ForEach(filteredChores, id: \.id) { chore in
                            EnhancedChoreRow(chore: chore, householdId: householdId, viewModel: viewModel, onComplete: { choreId in
                                // When completed, add to the hide set after delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    if let id = choreId {
                                        withAnimation(.easeOut) {
                                            completedChoreIds.insert(id)
                                        }
                                    }
                                }
                            })
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            deleteChores(at: indexSet)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
        }
        .navigationTitle("Chores")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddChore = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(AppTheme.primaryColor)
                }
            }
        }
        .sheet(isPresented: $showingAddChore) {
            AddChoreView(viewModel: viewModel, householdId: householdId)
        }
        .onAppear {
            viewModel.fetchChores(householdId: householdId)
            // Fix: This method doesn't exist, so we'll implement it in FirestoreViewModel.swift
            // viewModel.resetCompletedChores(householdId: householdId)
            handleResetCompletedChores()
            updateProgressWithAnimation()
        }
        // Fix: Changed from .onChange(of: viewModel.chores) to use onReceive with a publisher
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChoresDidUpdate"))) { _ in
            updateProgressWithAnimation()
        }
    }
    
    // Function to handle resetting completed chores
    private func handleResetCompletedChores() {
        // Check if chores need to be reset
        let defaults = UserDefaults.standard
        let lastResetDateKey = "lastChoreResetDate-\(householdId)"
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastResetDate = defaults.object(forKey: lastResetDateKey) as? Date {
            let lastResetDay = calendar.startOfDay(for: lastResetDate)
            
            // Only reset if it's a new day
            if lastResetDay < today {
                // Reset all completed chores
                resetCompletedChores()
                // Update the reset date
                defaults.set(today, forKey: lastResetDateKey)
            }
        } else {
            // First time checking, just set the date
            defaults.set(today, forKey: lastResetDateKey)
        }
    }
    
    // Function to reset completed chores
    private func resetCompletedChores() {
        let db = Firestore.firestore()
        
        // Get all completed chores
        db.collection("households").document(householdId).collection("chores")
            .whereField("isCompleted", isEqualTo: true)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents, !documents.isEmpty else { return }
                
                let batch = db.batch()
                
                for document in documents {
                    let choreRef = db.collection("households").document(householdId)
                        .collection("chores").document(document.documentID)
                    
                    // Reset isCompleted and remove completedAt
                    batch.updateData([
                        "isCompleted": false,
                        "completedAt": FieldValue.delete()
                    ], forDocument: choreRef)
                }
                
                // Commit the batch
                batch.commit { error in
                    if error == nil {
                        // Refresh the chores list
                        DispatchQueue.main.async {
                            viewModel.fetchChores(householdId: householdId)
                        }
                    }
                }
            }
    }
    
    private func calculateProgress() -> Double {
        let total = viewModel.chores.count
        guard total > 0 else { return 0 }
        let completed = viewModel.chores.filter { $0.isCompleted }.count
        return Double(completed) / Double(total)
    }
    
    private func updateProgressWithAnimation() {
        let progress = calculateProgress()
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            animatedProgress = progress
        }
    }
    
    private func deleteChores(at offsets: IndexSet) {
        let choresToDelete = offsets.map { viewModel.chores[$0] }
        
        for chore in choresToDelete {
            guard let choreId = chore.id else { continue }
            
            Firestore.firestore().collection("households").document(householdId)
                .collection("chores").document(choreId).delete()
        }
        
        // Refresh after deletion
        viewModel.fetchChores(householdId: householdId)
    }
}

struct EnhancedChoreRow: View {
    let chore: Chore
    let householdId: String
    @ObservedObject var viewModel: FirestoreViewModel
    var onComplete: ((String?) -> Void)? = nil
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Enhanced checkbox with status indication
                Button(action: {
                    toggleChoreCompletion()
                }) {
                    ZStack {
                        Circle()
                            .stroke(checkboxBorderColor, lineWidth: 2.5)
                            .frame(width: 32, height: 32)
                        
                        if chore.isCompleted {
                            Circle()
                                .fill(AppTheme.successColor)
                                .frame(width: 26, height: 26)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Circle()
                                .fill(checkboxFillColor)
                                .frame(width: 26, height: 26)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Enhanced chore details with better hierarchy
                VStack(alignment: .leading, spacing: 8) {
                    // Title with status styling
                    Text(chore.title)
                        .font(chore.isCompleted ? AppTheme.bodyFont : AppTheme.bodyBoldFont)
                        .strikethrough(chore.isCompleted)
                        .foregroundColor(chore.isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary)
                        .lineLimit(2)
                    
                    // Description if available
                    if let description = chore.description, !description.isEmpty {
                        Text(description)
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.textSecondary)
                            .lineLimit(2)
                    }
                    
                    // Enhanced metadata row
                    HStack(spacing: 12) {
                        // Assignee
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textTertiary)
                            
                            Text(chore.assignedTo)
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        // Separator
                        Circle()
                            .fill(AppTheme.textTertiary)
                            .frame(width: 3, height: 3)
                        
                        // Due date with smart formatting
                        HStack(spacing: 4) {
                            Image(systemName: dueDateIcon)
                                .font(.system(size: 12))
                                .foregroundColor(dueDateColor)
                            
                            Text(smartFormatDueDate(chore.dueDate))
                                .font(AppTheme.captionFont)
                                .foregroundColor(dueDateColor)
                        }
                        
                        Spacer()
                        
                        // Priority indicator for urgent items
                        if isUrgent {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.errorColor)
                                
                                Text("URGENT")
                                    .font(AppTheme.badgeFont)
                                    .foregroundColor(AppTheme.errorColor)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.errorColor.opacity(0.1))
                            .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                // Action menu button
                Menu {
                    Button(action: {
                        toggleChoreCompletion()
                    }) {
                        Label(chore.isCompleted ? "Mark Incomplete" : "Mark Complete",
                              systemImage: chore.isCompleted ? "circle" : "checkmark.circle")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: {
                        showingDeleteConfirmation = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            // Progress bar for overdue items
            if isOverdue && !chore.isCompleted {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(AppTheme.errorColor)
                            .frame(width: geometry.size.width * overdueProgress, height: 3)
                        
                        Rectangle()
                            .fill(AppTheme.errorColor.opacity(0.2))
                            .frame(height: 3)
                    }
                }
                .frame(height: 3)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(borderColor, lineWidth: isUrgent ? 2 : 1)
                )
        )
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Delete Chore"),
                message: Text("Are you sure you want to delete \"\(chore.title)\"? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteChore()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var checkboxBorderColor: Color {
        if chore.isCompleted {
            return AppTheme.successColor
        } else if isOverdue {
            return AppTheme.errorColor
        } else if isUrgent {
            return AppTheme.warningColor
        } else {
            return AppTheme.textTertiary
        }
    }
    
    private var checkboxFillColor: Color {
        if isOverdue {
            return AppTheme.errorColor.opacity(0.1)
        } else if isUrgent {
            return AppTheme.warningColor.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private var backgroundColor: Color {
        if chore.isCompleted {
            return AppTheme.successColor.opacity(0.05)
        } else if isOverdue {
            return AppTheme.errorColor.opacity(0.05)
        } else {
            return Color.white
        }
    }
    
    private var borderColor: Color {
        if chore.isCompleted {
            return AppTheme.successColor.opacity(0.3)
        } else if isOverdue {
            return AppTheme.errorColor.opacity(0.5)
        } else if isUrgent {
            return AppTheme.warningColor.opacity(0.5)
        } else {
            return Color.clear
        }
    }
    
    private var shadowColor: Color {
        if isOverdue {
            return AppTheme.errorColor.opacity(0.2)
        } else if isUrgent {
            return AppTheme.warningColor.opacity(0.1)
        } else {
            return AppTheme.cardShadow
        }
    }
    
    private var isOverdue: Bool {
        !chore.isCompleted && chore.dueDate < Date()
    }
    
    private var isUrgent: Bool {
        !chore.isCompleted && Calendar.current.isDateInToday(chore.dueDate)
    }
    
    private var dueDateColor: Color {
        if isOverdue {
            return AppTheme.errorColor
        } else if isUrgent {
            return AppTheme.warningColor
        } else if isDueSoon {
            return AppTheme.infoColor
        } else {
            return AppTheme.textSecondary
        }
    }
    
    private var dueDateIcon: String {
        if isOverdue {
            return "exclamationmark.triangle.fill"
        } else if isUrgent {
            return "clock.fill"
        } else {
            return "calendar"
        }
    }
    
    private var isDueSoon: Bool {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: chore.dueDate).day ?? 0
        return days <= 2 && days > 0
    }
    
    private var overdueProgress: Double {
        let daysSinceOverdue = Calendar.current.dateComponents([.day], from: chore.dueDate, to: Date()).day ?? 0
        return min(Double(daysSinceOverdue) / 7.0, 1.0) // Show progress for up to 7 days overdue
    }
    
    // MARK: - Helper Methods
    
    private func smartFormatDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if isOverdue {
            let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if days == 1 {
                return "1 day overdue"
            } else {
                return "\(days) days overdue"
            }
        } else if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today at \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Tomorrow at \(formatter.string(from: date))"
        } else {
            let days = calendar.dateComponents([.day], from: now, to: date).day ?? 0
            if days <= 7 {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                return formatter.string(from: date)
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                return formatter.string(from: date)
            }
        }
    }
    
    // MARK: - Actions
    
    private func deleteChore() {
        guard let choreId = chore.id else { return }
        
        viewModel.deleteChore(householdId: householdId, choreId: choreId) { success, _ in
            // Chore will be removed from the list automatically via fetchChores
        }
    }
    
    private func toggleChoreCompletion() {
        guard let choreId = chore.id else { return }
        
        Firestore.firestore().collection("households").document(householdId)
            .collection("chores").document(choreId)
            .updateData([
                "isCompleted": !chore.isCompleted,
                "completedAt": !chore.isCompleted ? Timestamp(date: Date()) : FieldValue.delete()
            ]) { error in
                if let error = error {
                    print("Error updating chore: \(error.localizedDescription)")
                } else {
                    // Refresh the data
                    viewModel.fetchChores(householdId: householdId)
                    
                    // Call the completion handler if chore was marked as completed
                    if !chore.isCompleted {
                        onComplete?(choreId)
                    }
                }
            }
    }
}
