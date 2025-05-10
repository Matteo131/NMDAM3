import SwiftUI
import Firebase

struct ExpenseDetailView: View {
    let expense: Expense
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    @State private var isShowingDeleteAlert = false
    @State private var isDeleting = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Expense header
                VStack(spacing: 8) {
                    Text(expense.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(expense.category.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("$\(String(format: "%.2f", expense.amount))")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(expense.category.color)
                        .padding(.vertical, 8)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Payment details
                GroupBox(label: Label("Payment Details", systemImage: "creditcard.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Paid by", value: expense.paidBy)
                        
                        DetailRow(label: "Date", value: formatDate(expense.paidAt, includeTime: true))
                        
                        DetailRow(label: "Split type", value: expense.splitType.rawValue)
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)
                
                // Split details
                GroupBox(label: Label("Split Details", systemImage: "person.2.fill")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Each person pays: $\(String(format: "%.2f", expense.amountPerPerson))")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        ForEach(expense.splitAmong, id: \.self) { person in
                            HStack {
                                Text(person)
                                
                                Spacer()
                                
                                if let settled = expense.settled[person], settled {
                                    Text("Settled")
                                        .foregroundColor(.green)
                                } else {
                                    Button("Mark as Settled") {
                                        markPersonAsSettled(person: person)
                                    }
                                    .foregroundColor(AppTheme.primaryColor)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)
                
                // Notes section
                if let notes = expense.notes, !notes.isEmpty {
                    GroupBox(label: Label("Notes", systemImage: "note.text")) {
                        Text(notes)
                            .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                }
                
                // Receipt image (loaded from local storage)
                if let receiptPath = expense.receiptPath, !receiptPath.isEmpty {
                    GroupBox(label: Label("Receipt", systemImage: "doc.text.image")) {
                        if let image = loadLocalImage(fromPath: receiptPath) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(8)
                                .padding(.vertical, 8)
                        } else {
                            Text("Receipt image unavailable on this device")
                                .foregroundColor(.gray)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Delete button
                Button(action: {
                    isShowingDeleteAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Expense")
                    }
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal)
                .disabled(isDeleting)
            }
            .padding(.vertical)
        }
        .navigationTitle("Expense Details")
        .alert(isPresented: $isShowingDeleteAlert) {
            Alert(
                title: Text("Delete Expense"),
                message: Text("Are you sure you want to delete this expense? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteExpense()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func formatDate(_ date: Date, includeTime: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = includeTime ? .short : .none
        return formatter.string(from: date)
    }
    
    private func loadLocalImage(fromPath path: String) -> UIImage? {
        guard !path.isEmpty else { return nil }
        
        let fileURL = URL(fileURLWithPath: path)
        do {
            let imageData = try Data(contentsOf: fileURL)
            return UIImage(data: imageData)
        } catch {
            print("Error loading image: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func markPersonAsSettled(person: String) {
        guard let expenseId = expense.id else { return }
        
        var updatedSettled = expense.settled
        updatedSettled[person] = true
        
        Firestore.firestore().collection("households").document(householdId)
            .collection("expenses").document(expenseId)
            .updateData([
                "settled.\(person)": true
            ]) { error in
                if let error = error {
                    print("Error updating settlement status: \(error.localizedDescription)")
                } else {
                    // Refresh expenses to update UI
                    viewModel.fetchExpenses(householdId: householdId)
                }
            }
    }
    
    private func deleteExpense() {
        guard let expenseId = expense.id else { return }
        isDeleting = true
        
        Firestore.firestore().collection("households").document(householdId)
            .collection("expenses").document(expenseId).delete { error in
                isDeleting = false
                
                if let error = error {
                    print("Error deleting expense: \(error.localizedDescription)")
                } else {
                    // Delete receipt image if exists
                    if let receiptPath = expense.receiptPath, !receiptPath.isEmpty {
                        do {
                            try FileManager.default.removeItem(atPath: receiptPath)
                        } catch {
                            print("Error deleting receipt image: \(error.localizedDescription)")
                        }
                    }
                    
                    // Refresh expenses and pop back to list
                    viewModel.fetchExpenses(householdId: householdId)
                }
            }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
