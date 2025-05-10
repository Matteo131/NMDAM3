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
        
        var body: some View {
            HStack {
                // Category icon
                ZStack {
                    Circle()
                        .fill(expense.category.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: expense.category.icon)
                        .foregroundColor(expense.category.color)
                }
                
                // Expense details
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.title)
                        .font(.headline)
                    
                    Text(expense.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Paid by: \(expense.paidBy)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatDate(expense.paidAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 8)
                
                Spacer()
                
                // Amount
                VStack(alignment: .trailing) {
                    Text("$\(expense.amount, specifier: "%.2f")")
                        .font(.headline)
                    
                    // Settlement status indicator
                    if expense.settled.values.allSatisfy({ $0 }) {
                        Text("Settled")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("Pending")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}
