//
//  HouseholdSwitcherView.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 24/04/2025.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct HouseholdSwitcherView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var households: [Household] = []
    @State private var isLoading = false
    @State private var showingCreateHousehold = false
    
    var body: some View {
        List {
            Section(header: Text("YOUR HOUSEHOLDS")) {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if households.isEmpty {
                    Text("You don't have any households")
                        .foregroundColor(.gray)
                } else {
                    ForEach(households) { household in
                        Button(action: {
                            authViewModel.currentHouseholdId = household.id
                        }) {
                            HStack {
                                Text(household.name)
                                
                                Spacer()
                                
                                if household.id == authViewModel.currentHouseholdId {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppTheme.primaryColor)
                                }
                            }
                        }
                    }
                }
                
                Button("Create New Household") {
                    showingCreateHousehold = true
                }
                .foregroundColor(AppTheme.primaryColor)
            }
        }
        .navigationTitle("Switch Household")
        .onAppear {
            fetchUserHouseholds()
        }
        .sheet(isPresented: $showingCreateHousehold) {
            CreateHouseholdView { householdId in
                if let householdId = householdId {
                    authViewModel.currentHouseholdId = householdId
                }
                fetchUserHouseholds()
            }
        }
    }
    
    private func fetchUserHouseholds() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            households = []
            return
        }
        
        isLoading = true
        
        // First get the user's household IDs
        Firestore.firestore().collection("users").document(userId).getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let householdIds = data["households"] as? [String] else {
                isLoading = false
                households = []
                return
            }
            
            if householdIds.isEmpty {
                isLoading = false
                households = []
                return
            }
            
            // Then fetch each household
            var fetchedHouseholds: [Household] = []
            let group = DispatchGroup()
            
            for householdId in householdIds {
                group.enter()
                
                Firestore.firestore().collection("households").document(householdId).getDocument { snapshot, error in
                    defer { group.leave() }
                    
                    guard let data = snapshot?.data(),
                          let name = data["name"] as? String,
                          let createdAtTimestamp = data["createdAt"] as? Timestamp else {
                        return
                    }
                    
                    let household = Household(
                        id: householdId,
                        name: name,
                        createdAt: createdAtTimestamp.dateValue()
                    )
                    
                    fetchedHouseholds.append(household)
                }
            }
            
            group.notify(queue: .main) {
                isLoading = false
                households = fetchedHouseholds.sorted(by: { $0.name < $1.name })
            }
        }
    }
}
