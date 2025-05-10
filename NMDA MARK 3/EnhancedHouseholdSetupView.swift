//
//  EnhancedHouseholdSetupView.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 04/05/2025.
//

// Create a new file named "EnhancedHouseholdSetupView.swift"

import SwiftUI
import Firebase

struct EnhancedHouseholdSetupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = HouseholdViewModel()
    @State private var householdName = ""
    @State private var isJoiningExisting = false
    @State private var inviteCode = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to NMDA!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                Text("Create your household or join an existing one")
                    .foregroundColor(.gray)
                
                if !isJoiningExisting {
                    // Create household form
                    VStack(spacing: 16) {
                        TextField("Household Name", text: $householdName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        Button(action: {
                            createHousehold()
                        }) {
                            if viewModel.isProcessing {
                                ProgressView()
                            } else {
                                Text("Create Household")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .disabled(householdName.isEmpty || viewModel.isProcessing)
                    }
                    
                    Button("or Join Existing") {
                        isJoiningExisting = true
                    }
                    .padding(.top)
                } else {
                    // Join household form
                    VStack(spacing: 16) {
                        TextField("Invite Code", text: $inviteCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        Button(action: {
                            joinHousehold()
                        }) {
                            if viewModel.isProcessing {
                                ProgressView()
                            } else {
                                Text("Join Household")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .disabled(inviteCode.isEmpty || viewModel.isProcessing)
                    }
                    
                    Button("Back to Create") {
                        isJoiningExisting = false
                    }
                    .padding(.top)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
        }
    }
    
    private func createHousehold() {
        guard let userId = authViewModel.user?.uid,
              let displayName = authViewModel.user?.displayName,
              let email = authViewModel.user?.email else {
            return
        }
        
        viewModel.createHousehold(
            name: householdName,
            userId: userId,
            displayName: displayName,
            email: email
        ) { householdId in
            if let householdId = householdId {
                // Update the current household ID in AuthViewModel
                authViewModel.currentHouseholdId = householdId
            }
        }
    }
    
    private func joinHousehold() {
        guard let userId = authViewModel.user?.uid,
              let displayName = authViewModel.user?.displayName,
              let email = authViewModel.user?.email else {
            return
        }
        
        viewModel.joinHouseholdWithCode(
            inviteCode: inviteCode,
            userId: userId,
            displayName: displayName,
            email: email
        ) { householdId in
            if let householdId = householdId {
                // Update the current household ID in AuthViewModel
                authViewModel.currentHouseholdId = householdId
            }
        }
    }
}
