//
//  HouseholdManagementView.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 24/04/2025.
//
import SwiftUI
import Firebase

struct HouseholdManagementView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = HouseholdViewModel()
    let householdId: String
    
    @State private var showingEditName = false
    @State private var showingInviteMember = false
    @State private var showingLeaveConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var newHouseholdName = ""
    
    var body: some View {
        Form {
            Section {
                // content
            } header: {
                Text("HOUSEHOLD INFO")
            
                if let household = viewModel.household {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(household.name)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(formatDate(household.createdAt))
                            .foregroundColor(.gray)
                    }
                    
                    if currentUserRole?.canEditHousehold == true {
                        Button("Edit Household Name") {
                            if let household = viewModel.household {
                                newHouseholdName = household.name
                                showingEditName = true
                            }
                        }
                        .foregroundColor(AppTheme.primaryColor)
                    }
                }
            }
            
            Section(header: Text("MEMBERS")) {
                ForEach(viewModel.members) { member in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(member.displayName)
                                .fontWeight(member.id == authViewModel.user?.uid ? .bold : .regular)
                            
                            Text(member.email)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text(member.role.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(roleColor(member.role))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    .contextMenu {
                        if canManageMember(member) {
                            Button {
                                showRoleChangeSheet(for: member)
                            } label: {
                                Label("Change Role", systemImage: "person.badge.key")
                            }
                            
                            Button(role: .destructive) {
                                confirmRemoveMember(member)
                            } label: {
                                Label("Remove from Household", systemImage: "person.crop.circle.badge.minus")
                            }
                        }
                    }
                }
                
                if currentUserRole?.canInvite == true {
                    Button("Invite Member") {
                        showingInviteMember = true
                    }
                    .foregroundColor(AppTheme.primaryColor)
                }
            }
            
            Section {
                if currentUserRole == .owner {
                    Button("Delete Household") {
                        showingDeleteConfirmation = true
                    }
                    .foregroundColor(.red)
                } else {
                    Button("Leave Household") {
                        showingLeaveConfirmation = true
                    }
                    .foregroundColor(.red)
                }
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
        .navigationTitle("Household Settings")
        .onAppear {
            loadData()
        }
        .alert("Edit Household Name", isPresented: $showingEditName) {
            TextField("Household Name", text: $newHouseholdName)
            
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                updateHouseholdName()
            }
        }
        .sheet(isPresented: $showingInviteMember) {
            InviteMemberView(viewModel: viewModel, householdId: householdId, householdName: viewModel.household?.name ?? "")
        }
        .alert("Leave Household", isPresented: $showingLeaveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Leave", role: .destructive) {
                leaveHousehold()
            }
        } message: {
            Text("Are you sure you want to leave this household? You'll need a new invitation to join again.")
        }
        .alert("Delete Household", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteHousehold()
            }
        } message: {
            Text("Are you sure you want to delete this household? This action cannot be undone and will remove the household for all members.")
        }
    }
    
    private var currentUserRole: HouseholdRole? {
        guard let userId = authViewModel.user?.uid else { return nil }
        return viewModel.members.first(where: { $0.id == userId })?.role
    }
    
    private func loadData() {
        viewModel.fetchHousehold(householdId: householdId) {
            viewModel.fetchHouseholdMembers(householdId: householdId)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func roleColor(_ role: HouseholdRole) -> Color {
        switch role {
        case .owner: return .purple
        case .admin: return .blue
        case .member: return .gray
        }
    }
    
    private func canManageMember(_ member: HouseholdMember) -> Bool {
        guard let currentRole = currentUserRole else { return false }
        
        // Can't manage yourself
        if member.id == authViewModel.user?.uid { return false }
        
        // Owners can manage anyone
        if currentRole == .owner { return true }
        
        // Admins can only manage members
        if currentRole == .admin && member.role == .member { return true }
        
        return false
    }
    
    private func showRoleChangeSheet(for member: HouseholdMember) {
        // In a real app, show an action sheet with role options
        print("Change role for \(member.displayName)")
    }
    
    private func confirmRemoveMember(_ member: HouseholdMember) {
        // In a real app, show a confirmation dialog
        print("Remove \(member.displayName)")
    }
    
    private func updateHouseholdName() {
        guard !newHouseholdName.isEmpty else { return }
        
        viewModel.updateHouseholdName(householdId: householdId, newName: newHouseholdName) { success in
            if success {
                loadData()
            }
        }
    }
    
    private func leaveHousehold() {
        guard let userId = authViewModel.user?.uid else { return }
        
        viewModel.leaveHousehold(householdId: householdId, userId: userId) { success in
            if success {
                // Reset current household ID
                authViewModel.currentHouseholdId = nil
            }
        }
    }
    
    private func deleteHousehold() {
        viewModel.deleteHousehold(householdId: householdId) { success in
            if success {
                // Reset current household ID
                authViewModel.currentHouseholdId = nil
            }
        }
    }
}
