import SwiftUI
import Firebase
import FirebaseAuth

struct AddChoreView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    
    @State private var title = ""
    @State private var description = ""
    @State private var assignedTo = "You"
    @State private var dueDate = Date()
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var householdMemberNames: [String] = ["You"]
    @State private var isRecurring = false
    @State private var recurrence: ChoreRecurrence?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("CHORE DETAILS")) {
                    TextField("Title", text: $title)
                    
                    TextField("Description (optional)", text: $description)
                        .frame(height: 80)
                    
                    Picker("Assigned To", selection: $assignedTo) {
                        ForEach(householdMemberNames, id: \.self) { member in
                            Text(member).tag(member)
                        }
                    }
                    
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                }
                Section(header: Text("RECURRING")) {
                    RecurringChoreView(isRecurring: $isRecurring, recurrence: $recurrence)
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
                        addChore()
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
                                Text("Add Chore")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                    .disabled(isProcessing || title.isEmpty)
                }
            }
            .navigationTitle("Add Chore")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
            .onAppear {
                // Check for current user
                if let currentUser = Auth.auth().currentUser?.displayName {
                    // Add current user if not already in list
                    if !householdMemberNames.contains(currentUser) {
                        householdMemberNames.append(currentUser)
                    }
                }
            }
        }
    }
    
    // This is now correctly placed outside of the body property
    private func addChore() {
        isProcessing = true
        errorMessage = nil
        
        // Manual implementation instead of using the viewModel method
        var choreData: [String: Any] = [
                "title": title,
                "description": description.isEmpty ? "" : description,
                "assignedTo": assignedTo,
                "dueDate": Timestamp(date: dueDate),
                "isCompleted": false,
                "createdAt": Timestamp(date: Date()),
                "isRecurring": isRecurring
            ]
            
            // Add recurrence data if present
            if let recurrence = recurrence {
                choreData["recurrence"] = [
                    "frequency": recurrence.frequency.rawValue,
                    "daysOfWeek": recurrence.daysOfWeek ?? [],
                    "dayOfMonth": recurrence.dayOfMonth ?? 0,
                    "nextDueDate": Timestamp(date: recurrence.nextDueDate)
                ]
            }
        
        Firestore.firestore().collection("households").document(householdId).collection("chores")
            .addDocument(data: choreData) { error in
                DispatchQueue.main.async {
                    self.isProcessing = false
                    
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                    } else {
                        // Refresh the chores list
                        self.viewModel.fetchChores(householdId: self.householdId)
                        self.dismiss()
                    }
                }
            }
    }
}
