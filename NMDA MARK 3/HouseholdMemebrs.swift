//
//  HouseholdMemebrs.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 04/05/2025.
//
import SwiftUI
import Firebase
import FirebaseAuth

struct HouseholdMembersView: View {
    let householdId: String
    @StateObject private var viewModel = HouseholdViewModel()
    @State private var showingInviteSheet = false
    
    var body: some View {
        List {
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
                    
                    // Show role badge
                    Text(member.role.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(roleBadgeColor(for: member.role))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .padding(.vertical, 4)
            }
            
            Section {
                Button(action: {
                    showingInviteSheet = true
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Invite Member")
                    }
                    .foregroundColor(AppTheme.primaryColor)
                }
            }
        }
        .navigationTitle("Household Members")
        .onAppear {
            viewModel.fetchHouseholdMembers(householdId: householdId)
        }
        .sheet(isPresented: $showingInviteSheet) {
            // Get household name for the invite sheet
            if let household = viewModel.household {
                InviteMemberView(viewModel: viewModel,
                                householdId: householdId,
                                householdName: household.name)
            } else {
                // Fallback if household name isn't available
                InviteMemberView(viewModel: viewModel,
                                householdId: householdId,
                                householdName: "Your Household")
            }
        }
    }
    
    private func roleBadgeColor(for role: HouseholdRole) -> Color {
        switch role {
        case .owner:
            return .purple
        case .admin:
            return .blue
        case .member:
            return .gray
        }
    }
}
