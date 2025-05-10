import SwiftUI
import Firebase
import FirebaseFirestore

// In ChoresView.swift, here's the corrected code:

struct ChoresView: View {
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    @State private var showingAddChore = false
    @State private var completedChoreIds: Set<String> = []
    @State private var animatedProgress: Double = 0
    
    private var filteredChores: [Chore] {
        viewModel.chores.filter { chore in
            !(chore.isCompleted && completedChoreIds.contains(chore.id ?? ""))
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
                            
                            Text("\(viewModel.chores.filter { !$0.isCompleted }.count) pending")
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
                    
                    // List of chores
                    List {
                        ForEach(viewModel.chores.filter { chore in
                            // Don't show if it's completed and in the hiding set
                            !(chore.isCompleted && completedChoreIds.contains(chore.id ?? ""))
                        }, id: \.id) { chore in
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
            viewModel.resetCompletedChores(householdId: householdId)
            updateProgressWithAnimation()
        }
        .onChange(of: viewModel.chores) { _ in
            updateProgressWithAnimation()
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
        VStack {
            HStack(spacing: 16) {
                // Checkbox - existing code
                Button(action: {
                    toggleChoreCompletion()
                }) {
                    ZStack {
                        Circle()
                            .stroke(chore.isCompleted ? AppTheme.secondaryColor : Color.gray.opacity(0.5), lineWidth: 2)
                            .frame(width: 28, height: 28)
                        
                        if chore.isCompleted {
                            Circle()
                                .fill(AppTheme.secondaryColor)
                                .frame(width: 22, height: 22)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Chore details - existing code
                VStack(alignment: .leading, spacing: 4) {
                    Text(chore.title)
                        .font(.headline)
                        .strikethrough(chore.isCompleted)
                        .foregroundColor(chore.isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary)
                    
                    if let description = chore.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Label(
                            title: { Text(chore.assignedTo).font(.caption) },
                            icon: { Image(systemName: "person.fill") }
                        )
                        .foregroundColor(AppTheme.textSecondary)
                        
                        Spacer()
                        
                        Label(
                            title: { Text(formatDueDate(chore.dueDate)).font(.caption) },
                            icon: { Image(systemName: "calendar") }
                        )
                        .foregroundColor(dueDateColor)
                    }
                }
                
                Spacer()
                
                // Add delete button
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(AppTheme.errorColor.opacity(0.7))
                        .padding(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Delete Chore"),
                message: Text("Are you sure you want to delete this chore? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteChore()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    
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
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private var dueDateColor: Color {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: chore.dueDate).day ?? 0
        
        if days < 0 {
            return .red // Overdue
        } else if days == 0 {
            return .orange // Due today
        } else if days <= 2 {
            return AppTheme.primaryColor // Due soon
        } else {
            return AppTheme.textSecondary // Due later
        }
    }
}
