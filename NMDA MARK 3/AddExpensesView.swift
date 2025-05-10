import SwiftUI
import Firebase
import FirebaseAuth

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    
    @State private var title = ""
    @State private var amount = ""
    @State private var paidBy = Auth.auth().currentUser?.uid ?? ""
    @State private var paidAt = Date()
    @State private var category: ExpenseCategory = .other
    @State private var splitType: SplitType = .equal
    @State private var splitAmong: [String] = []
    @State private var notes = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    // Directly use the householdMembers property
    var householdMembers: [HouseholdMember] {
        return viewModel.householdMembers
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Use the AppTheme background
                Color.gray.opacity(0.1).ignoresSafeArea()
                
                Form {
                    Section(header: Text("EXPENSE DETAILS").foregroundColor(AppTheme.primaryColor)) {
                        TextField("Title", text: $title)
                            .padding(.vertical, 8)
                        
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .padding(.vertical, 8)
                        
                        Picker("Category", selection: $category) {
                            ForEach(ExpenseCategory.allCases, id: \.self) { category in
                                Label(
                                    title: { Text(category.rawValue) },
                                    icon: { Image(systemName: category.icon) }
                                )
                                .foregroundColor(category.color)
                                .tag(category)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        Picker("Paid By", selection: $paidBy) {
                            ForEach(householdMembers, id: \.id) { member in
                                Text(member.displayName).tag(member.id ?? "")
                            }
                        }
                        .padding(.vertical, 8)
                        
                        DatePicker("Date", selection: $paidAt, displayedComponents: [.date])
                            .padding(.vertical, 8)
                    }
                    
                    Section(header: Text("SPLIT DETAILS").foregroundColor(AppTheme.primaryColor)) {
                        Picker("Split Type", selection: $splitType) {
                            ForEach(SplitType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        ForEach(householdMembers, id: \.id) { member in
                            Toggle(member.displayName, isOn: Binding(
                                get: { splitAmong.contains(member.id ?? "") },
                                set: { isIncluded in
                                    if isIncluded {
                                        if let id = member.id {
                                            splitAmong.append(id)
                                        }
                                    } else {
                                        splitAmong.removeAll { $0 == member.id }
                                    }
                                }
                            ))
                            .padding(.vertical, 4)
                        }
                        
                        if !splitAmong.isEmpty {
                            HStack {
                                Text("Each person pays:")
                                Spacer()
                                Text("$\(perPersonAmount)")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.primaryColor)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    Section(header: Text("ADDITIONAL INFO").foregroundColor(AppTheme.primaryColor)) {
                        TextField("Notes (optional)", text: $notes)
                            .padding(.vertical, 8)
                    }
                    
                    if let errorMessage = errorMessage {
                        Section {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Section {
                        Button(action: {
                            addExpense()
                        }) {
                            if isProcessing {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                            } else {
                                HStack {
                                    Spacer()
                                    Text("Add Expense")
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(isFormValid ? AppTheme.primaryColor : AppTheme.primaryColor.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.cornerRadius)
                        .disabled(isProcessing || !isFormValid)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            }
            .foregroundColor(AppTheme.primaryColor))
            .onAppear {
                // Default to current user
                if let currentUserId = Auth.auth().currentUser?.uid {
                    paidBy = currentUserId
                    splitAmong = [currentUserId]
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        // Validate required fields
        guard !title.isEmpty,
              let amountValue = Double(amount),
              amountValue > 0,
              !paidBy.isEmpty,
              !splitAmong.isEmpty else {
            return false
        }
        return true
    }
    
    private var perPersonAmount: String {
        guard let amountValue = Double(amount), !splitAmong.isEmpty else {
            return "0.00"
        }
        
        let perPerson = amountValue / Double(splitAmong.count)
        return String(format: "%.2f", perPerson)
    }
    
    private func addExpense() {
        guard let amountValue = Double(amount) else {
            errorMessage = "Please enter a valid amount"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        // Create a dictionary of settlement status for each person
        var settled: [String: Bool] = [:]
        for person in splitAmong {
            // The person who paid is automatically settled
            settled[person] = (person == paidBy)
        }
        
        let expenseData: [String: Any] = [
            "title": title,
            "amount": amountValue,
            "paidBy": paidBy,
            "paidAt": Timestamp(date: paidAt),
            "category": category.rawValue,
            "splitType": splitType.rawValue,
            "splitAmong": splitAmong,
            "settled": settled,
            "notes": notes,
            "createdAt": Timestamp(date: Date())
        ]
        
        Firestore.firestore().collection("households").document(householdId)
            .collection("expenses").addDocument(data: expenseData) { error in
                DispatchQueue.main.async {
                    self.isProcessing = false
                    
                    if let error = error {
                        self.errorMessage = "Error saving expense: \(error.localizedDescription)"
                    } else {
                        // Refresh expenses list and dismiss
                        self.viewModel.fetchExpenses(householdId: self.householdId)
                        self.dismiss()
                    }
                }
            }
    }
}
