//
//  CreateHouseholdView.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 24/04/2025.
//
import SwiftUI
import Firebase
import FirebaseAuth

struct CreateHouseholdView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = HouseholdViewModel()
    let onComplete: (String?) -> Void
    
    @State private var householdName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("HOUSEHOLD DETAILS")) {
                    TextField("Household Name", text: $householdName)
                }
                
                Section {
                    Button("Create Household") {
                        createHousehold()
                    }
                    .disabled(householdName.isEmpty || viewModel.isProcessing)
                }
                
                if viewModel.isProcessing {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Create Household")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private func createHousehold() {
        guard let userId = Auth.auth().currentUser?.uid,
              let displayName = Auth.auth().currentUser?.displayName,
              let email = Auth.auth().currentUser?.email else {
            return
        }
        
        viewModel.createHousehold(
            name: householdName,
            userId: userId,
            displayName: displayName,
            email: email
        ) { householdId in
            onComplete(householdId)
            dismiss()
        }
    }
}
