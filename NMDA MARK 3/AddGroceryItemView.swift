import SwiftUI
import Firebase

struct AddGroceryItemView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    
    @State private var name = ""
    @State private var category = "Produce"
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    private let categories = [
        "Produce", "Dairy", "Meat", "Bakery",
        "Frozen", "Pantry", "Beverages", "Household", "Other"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("ITEM DETAILS")) {
                    TextField("Item Name", text: $name)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
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
                        addGroceryItem()
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
                                Text("Add Item")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                    .disabled(isProcessing || name.isEmpty)
                }
            }
            .navigationTitle("Add Grocery Item")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private func addGroceryItem() {
        isProcessing = true
        errorMessage = nil
        
        // Manual implementation instead of using the viewModel method
        let itemData: [String: Any] = [
            "name": name,
            "category": category,
            "addedBy": "You", // In a real app, use the current user's name
            "addedAt": Timestamp(date: Date()),
            "isCompleted": false
        ]
        
        Firestore.firestore().collection("households").document(householdId).collection("groceryItems")
            .addDocument(data: itemData) { error in
                DispatchQueue.main.async {
                    self.isProcessing = false
                    
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                    } else {
                        // Refresh the grocery items list
                        self.viewModel.fetchGroceryItems(householdId: self.householdId)
                        self.dismiss()
                    }
                }
            }
    }
}
