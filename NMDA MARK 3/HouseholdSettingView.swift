import SwiftUI
import Firebase
import FirebaseAuth

struct HouseholdSettingsView: View {
    @ObservedObject var viewModel: HouseholdViewModel
    let householdId: String
    @State private var showingInviteSheet = false
    @State private var isEditingName = false
    @State private var newHouseholdName = ""
    @State private var inviteCode: String? = nil
    @State private var isGeneratingCode = false
    @State private var showingInviteCode = false
    
    var body: some View {
        Form {
            Section(header: Text("HOUSEHOLD INFO")) {
                if let household = viewModel.household {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(household.name)
                            .foregroundColor(.gray)
                    }
                    
                    if currentUserRole?.canEditHousehold == true {
                        Button("Edit Household Name") {
                            isEditingName = true
                            newHouseholdName = household.name
                        }
                        .foregroundColor(AppTheme.primaryColor)
                    }
                }
            }
            
            Section(header: Text("INVITE MEMBERS")) {
                Button("Generate Invite Code") {
                    isGeneratingCode = true
                    generateInviteCode()
                }
                .foregroundColor(AppTheme.primaryColor)
                .disabled(isGeneratingCode)
            }
            
            Section(header: Text("MEMBERS")) {
                if viewModel.isProcessing {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    ForEach(viewModel.members) { member in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(member.displayName)
                                    .fontWeight(member.id == Auth.auth().currentUser?.uid ? .bold : .regular)
                                
                                Text(member.email)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            RoleBadge(role: member.role)
                        }
                    }
                    
                    if currentUserRole?.canInvite == true {
                        Button("Invite Member") {
                            showingInviteSheet = true
                        }
                        .foregroundColor(AppTheme.primaryColor)
                    }
                }
            }
            
            if currentUserRole == .owner {
                Section {
                    Button("Delete Household") {
                        // Show confirmation dialog
                    }
                    .foregroundColor(.red)
                }
            } else {
                Section {
                    Button("Leave Household") {
                        // Show confirmation dialog
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Household Settings")
        .sheet(isPresented: $showingInviteSheet) {
            InviteMemberView(viewModel: viewModel, householdId: householdId, householdName: viewModel.household?.name ?? "")
        }
        .alert("Edit Household Name", isPresented: $isEditingName) {
            TextField("Household Name", text: $newHouseholdName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                updateHouseholdName()
            }
        }
        .alert(isPresented: $showingInviteCode) {
            Alert(
                title: Text("Invite Code"),
                message: Text("Share this code with others to join your household:\n\n\(inviteCode ?? "")"),
                dismissButton: .default(Text("Copy"), action: {
                    UIPasteboard.general.string = inviteCode
                })
            )
        }
        .onAppear {
            viewModel.fetchHousehold(householdId: householdId)
            viewModel.fetchHouseholdMembers(householdId: householdId)
        }
    }
    
    var currentUserRole: HouseholdRole? {
        guard let userId = Auth.auth().currentUser?.uid else { return nil }
        return viewModel.members.first(where: { $0.id == userId })?.role
    }
    
    func updateHouseholdName() {
        guard !newHouseholdName.isEmpty else { return }
        
        viewModel.updateHouseholdName(householdId: householdId, newName: newHouseholdName) { success in
            if success {
                viewModel.fetchHousehold(householdId: householdId)
            }
        }
    }
    
    func generateInviteCode() {
        guard let userId = Auth.auth().currentUser?.uid,
              let displayName = Auth.auth().currentUser?.displayName else {
            isGeneratingCode = false
            return
        }
        
        viewModel.createHouseholdInvitation(
            householdId: householdId,
            householdName: viewModel.household?.name ?? "Household",
            invitedBy: userId,
            invitedByName: displayName,
            inviteeEmail: ""
        ) { code in
            isGeneratingCode = false
            if let code = code {
                inviteCode = code
                showingInviteCode = true
            }
        }
    }
}

struct RoleBadge: View {
    let role: HouseholdRole
    
    var body: some View {
        Text(role.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(roleColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    var roleColor: Color {
        switch role {
        case .owner: return .purple
        case .admin: return .blue
        case .member: return .gray
        }
    }
}
