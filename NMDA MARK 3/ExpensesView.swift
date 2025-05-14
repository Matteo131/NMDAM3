import SwiftUI
import Firebase
import FirebaseAuth

struct ExpensesView: View {
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    @State private var showingAddExpense = false
    @State private var showingSettledExpenses = false
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Loading expenses...")
            } else if viewModel.expenses.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No expenses yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("Add your shared expenses and split them with your roommates")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    Button("Add Expense") {
                        showingAddExpense = true
                    }
                    .padding()
                    .background(AppTheme.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            } else {
                VStack {
                    // Filter toggle
                    Toggle("Show settled expenses", isOn: $showingSettledExpenses)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Summary section
                    VStack {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Expenses")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text("$\(totalExpensesAmount, specifier: "%.2f")")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Your Balance")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text("$\(yourBalance, specifier: "%.2f")")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(yourBalance >= 0 ? .green : .red)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    
                    // Expenses list
                    List {
                        ForEach(filteredExpenses) { expense in
                            NavigationLink(destination: ExpenseDetailView(expense: expense, viewModel: viewModel, householdId: householdId)) {
                                ExpenseRow(expense: expense)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Expenses")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddExpense = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(viewModel: viewModel, householdId: householdId)
        }
        .onAppear {
            viewModel.fetchExpenses(householdId: householdId)
        }
    }
    
    var filteredExpenses: [Expense] {
        viewModel.expenses.filter { expense in
            if showingSettledExpenses {
                return true
            } else {
                // Check if there are any unsettled payments
                return expense.settled.values.contains(false)
            }
        }
    }
    
    var totalExpensesAmount: Double {
        viewModel.expenses.reduce(0) { $0 + $1.amount }
    }
    
    var yourBalance: Double {
        guard let userId = Auth.auth().currentUser?.uid else { return 0 }
        
        var balance: Double = 0
        
        for expense in viewModel.expenses {
            // If you paid for it
            if expense.paidBy == userId {
                // Add the amount others owe you
                for person in expense.splitAmong where person != userId {
                    if let settled = expense.settled[person], !settled {
                        balance += expense.amountPerPerson
                    }
                }
            }
            // If you need to pay for it
            else if expense.splitAmong.contains(userId) {
                if let settled = expense.settled[userId], !settled {
                    balance -= expense.amountPerPerson
                }
            }
        }
        
        return balance
    }
}

struct ExpenseRow: View {
    let expense: Expense
    @State private var showingQuickSettle = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Enhanced category icon with status indication
                ZStack {
                    Circle()
                        .fill(expense.category.color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: expense.category.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(expense.category.color)
                    
                    // Settlement status indicator
                    if !isFullySettled {
                        Circle()
                            .fill(AppTheme.warningColor)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Image(systemName: "exclamationmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 18, y: -18)
                    }
                }
                
                // Enhanced expense details with better hierarchy
                VStack(alignment: .leading, spacing: 6) {
                    // Title and amount row
                    HStack {
                        Text(expense.title)
                            .font(AppTheme.bodyBoldFont)
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text("£\(expense.amount, specifier: "%.2f")")
                            .font(AppTheme.numberFont)
                            .foregroundColor(expense.category.color)
                    }
                    
                    // Category and date
                    HStack(spacing: 8) {
                        Text(expense.category.rawValue)
                            .font(AppTheme.captionFont)
                            .foregroundColor(expense.category.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(expense.category.color.opacity(0.1))
                            .cornerRadius(4)
                        
                        Text("•")
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.textTertiary)
                        
                        Text(smartFormatDate(expense.paidAt))
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Spacer()
                    }
                    
                    // Enhanced settlement info
                    HStack(spacing: 12) {
                        // Paid by info
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textTertiary)
                            
                            Text("Paid by \(expense.paidBy)")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Settlement status with action
                        if isFullySettled {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.successColor)
                                
                                Text("Settled")
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(AppTheme.successColor)
                            }
                        } else {
                            Button(action: {
                                showingQuickSettle = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 12))
                                    
                                    Text("\(pendingCount) pending")
                                        .font(AppTheme.captionFont)
                                }
                                .foregroundColor(AppTheme.warningColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.warningColor.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
            }
            
            // Quick settlement preview (only for unsettled expenses)
            if !isFullySettled && showingQuickSettle {
                VStack(spacing: 8) {
                    Divider()
                    
                    HStack {
                        Text("Settlement Details")
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Spacer()
                        
                        Button("Hide") {
                            showingQuickSettle = false
                        }
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.primaryColor)
                    }
                    
                    // Settlement breakdown
                    VStack(spacing: 4) {
                        ForEach(expense.splitAmong, id: \.self) { person in
                            if let settled = expense.settled[person] {
                                HStack {
                                    Text(person)
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Text("£\(expense.amountPerPerson, specifier: "%.2f")")
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    if settled {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppTheme.successColor)
                                    } else {
                                        Button("Settle") {
                                            markPersonAsSettled(person: person)
                                        }
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(AppTheme.primaryColor)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(AppTheme.primaryColor.opacity(0.1))
                                        .cornerRadius(4)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Computed Properties
    
    private var isFullySettled: Bool {
        expense.settled.values.allSatisfy { $0 }
    }
    
    private var pendingCount: Int {
        expense.settled.values.filter { !$0 }.count
    }
    
    private var backgroundColor: Color {
        isFullySettled ? AppTheme.successColor.opacity(0.05) : Color.white
    }
    
    private var borderColor: Color {
        isFullySettled ? AppTheme.successColor.opacity(0.3) : Color.clear
    }
    
    // MARK: - Helper Methods
    
    private func smartFormatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
            if days <= 7 {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE" // Day name
                return formatter.string(from: date)
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                return formatter.string(from: date)
            }
        }
    }
    
    private func markPersonAsSettled(person: String) {
        // This would be implemented with proper Firebase update
        // For now, just provide the structure
        print("Marking \(person) as settled for expense: \(expense.title)")
        
        // In real implementation:
        // 1. Update Firestore document
        // 2. Refresh the parent view
        // 3. Show success feedback
    }
}
