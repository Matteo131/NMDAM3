import SwiftUI
import Firebase
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("ACCOUNT INFORMATION")) {
                HStack {
                    Text("Email")
                    Spacer()
                    Text(Auth.auth().currentUser?.email ?? "Not available")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("Name")
                    Spacer()
                    Text(Auth.auth().currentUser?.displayName ?? "Not available")
                        .foregroundColor(.gray)
                }
            }
            
            Section(header: Text("HOUSEHOLD")) {
                NavigationLink(destination: HouseholdSwitcherView()) {
                    HStack {
                        Text("Switch Household")
                        Spacer()
                        Image(systemName: "house.fill")
                            .foregroundColor(AppTheme.primaryColor)
                    }
                }
                
                if let householdId = authViewModel.currentHouseholdId {
                    NavigationLink(destination: HouseholdSettingsView(viewModel: HouseholdViewModel(), householdId: householdId)) {
                        HStack {
                            Text("Household Settings")
                            Spacer()
                            Image(systemName: "gear")
                                .foregroundColor(AppTheme.primaryColor)
                        }
                    }
                    
                    Button(action: {
                        showAlert = true
                    }) {
                        HStack {
                            Text("Leave Household")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            Section {
                Button(action: {
                    authViewModel.signOut()
                }) {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Leave Household"),
                message: Text("Are you sure you want to leave this household? You will lose access to all shared chores, groceries, and events."),
                primaryButton: .destructive(Text("Leave")) {
                    leaveHousehold()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func leaveHousehold() {
        guard let householdId = authViewModel.currentHouseholdId,
              let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Remove user from household
        Firestore.firestore().collection("households").document(householdId)
            .collection("members").document(userId).delete()
        
        // Update the household document
        Firestore.firestore().collection("households").document(householdId)
            .updateData([
                "memberIds": FieldValue.arrayRemove([userId])
            ])
        
        // Update user's document
        Firestore.firestore().collection("users").document(userId)
            .updateData([
                "households": FieldValue.arrayRemove([householdId]),
                "currentHouseholdId": FieldValue.delete()
            ]) { error in
                if let error = error {
                    print("Error leaving household: \(error.localizedDescription)")
                } else {
                    // Reset current household ID
                    authViewModel.currentHouseholdId = nil
                }
            }
    }
}
