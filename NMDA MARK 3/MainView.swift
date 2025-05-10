import SwiftUI

struct MainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // For testing purposes
    private let testHouseholdId = "wbjt48ft88QtEN3hWtD4" // Replace with your Firebase household ID
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if let householdId = authViewModel.currentHouseholdId {
                    EnhancedMainTabView(householdId: householdId)
                } else {
                    // If authenticated but no household
                    HouseholdSetupView()
                }
            } else {
                LoginView()
            }
        }
    }
}

struct HouseholdSetupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var householdName = ""
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("CREATE HOUSEHOLD")) {
                    TextField("Household Name", text: $householdName)
                    
                    Button(action: {
                        // This would create a household in Firebase
                        // For now, just hardcode a household ID
                        authViewModel.currentHouseholdId = "YOUR_HOUSEHOLD_ID" // Same as testHouseholdId
                    }) {
                        if isCreating {
                            ProgressView()
                        } else {
                            Text("Create Household")
                        }
                    }
                    .disabled(householdName.isEmpty || isCreating)
                }
            }
            .navigationTitle("Set Up Household")
        }
    }
}
