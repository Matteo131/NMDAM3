//
//  InviteMembersView.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 24/04/2025.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct InviteMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: HouseholdViewModel
    let householdId: String
    let householdName: String
    
    @State private var email = ""
    @State private var inviteCode: String?
    @State private var hasInvited = false
    
    var body: some View {
        NavigationView {
            Form {
                if hasInvited, let inviteCode = inviteCode {
                    Section(header: Text("INVITATION CREATED")) {
                        Text("Share this code with your roommate:")
                            .font(.headline)
                        
                        Text(inviteCode)
                            .font(.system(.title, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        Button("Copy to Clipboard") {
                            UIPasteboard.general.string = inviteCode
                        }
                        .foregroundColor(AppTheme.primaryColor)
                    }
                    
                    Section {
                        Button("Done") {
                            dismiss()
                        }
                    }
                } else {
                    Section(header: Text("INVITE MEMBER")) {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        Button("Send Invitation") {
                            sendInvitation()
                        }
                        .disabled(email.isEmpty || !isValidEmail(email) || viewModel.isProcessing)
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
            }
            .navigationTitle("Invite Member")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private func sendInvitation() {
        guard let userId = Auth.auth().currentUser?.uid,
              let displayName = Auth.auth().currentUser?.displayName else {
            return
        }
        
        viewModel.createHouseholdInvitation(
            householdId: householdId,
            householdName: householdName,
            invitedBy: userId,
            invitedByName: displayName,
            inviteeEmail: email
        ) { code in
            if let code = code {
                inviteCode = code
                hasInvited = true
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
