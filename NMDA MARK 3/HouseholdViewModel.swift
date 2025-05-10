//
//  HouseholdViewModel.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 24/04/2025.
//
import Foundation
import Firebase
import FirebaseFirestore

class HouseholdViewModel: ObservableObject {
    @Published var household: Household?
    @Published var members: [HouseholdMember] = []
    @Published var invitations: [HouseholdInvitation] = []
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    
    func createHousehold(name: String, userId: String, displayName: String, email: String, completion: @escaping (String?) -> Void) {
        isProcessing = true
        errorMessage = nil
        
        // Create the household document
        let householdData: [String: Any] = [
            "name": name,
            "createdBy": userId,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date()),
            "memberIds": [userId], // Add this to track member IDs
            "members": [[
                "id": userId,
                "displayName": displayName,
                "email": email,
                "role": HouseholdRole.owner.rawValue,
                "joinedAt": Timestamp(date: Date())
            ]]
        ]
        
        // First create the household
        var householdRef: DocumentReference? = nil
        householdRef = db.collection("households").addDocument(data: householdData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.errorMessage = "Failed to create household: \(error.localizedDescription)"
                    completion(nil)
                }
                return
            }
            
            guard let householdId = householdRef?.documentID else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.errorMessage = "Failed to get household ID"
                    completion(nil)
                }
                return
            }
            
            // Add the household to the user's households array
            self.db.collection("users").document(userId)
                .updateData([
                    "households": FieldValue.arrayUnion([householdId]),
                    "currentHouseholdId": householdId // Add this to track current household
                ]) { error in
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        
                        if let error = error {
                            self.errorMessage = "Failed to update user: \(error.localizedDescription)"
                            completion(nil)
                        } else {
                            completion(householdId)
                        }
                    }
                }
        }
    }
    
    func fetchHouseholdMembers(householdId: String) {
        isProcessing = true
        
        db.collection("households").document(householdId)
            .collection("members").getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isProcessing = false
                    
                    if let error = error {
                        self.errorMessage = "Failed to fetch members: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.members = []
                        return
                    }
                    
                    self.members = documents.compactMap { document -> HouseholdMember? in
                        let data = document.data()
                        
                        guard let displayName = data["displayName"] as? String,
                              let email = data["email"] as? String,
                              let roleString = data["role"] as? String,
                              let role = HouseholdRole(rawValue: roleString),
                              let joinedAtTimestamp = data["joinedAt"] as? Timestamp else {
                            return nil
                        }
                        
                        let joinedAt = joinedAtTimestamp.dateValue()
                        let profileImageURL = data["profileImageURL"] as? String
                        
                        return HouseholdMember(
                            id: document.documentID,
                            displayName: displayName,
                            email: email,
                            role: role,
                            joinedAt: joinedAt,
                            profileImageURL: profileImageURL
                        )
                    }
                }
            }
    }
    
    func createHouseholdInvitation(householdId: String, householdName: String, invitedBy: String, invitedByName: String, inviteeEmail: String, completion: @escaping (String?) -> Void) {
        isProcessing = true
        errorMessage = nil
        
        // Generate a random 8-character invite code
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let code = String((0..<8).map { _ in letters.randomElement()! })
        
        // Set expiration to 7 days from now
        let expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        
        let invitationData: [String: Any] = [
            "householdId": householdId,
            "householdName": householdName,
            "invitedBy": invitedBy,
            "invitedByName": invitedByName,
            "inviteeEmail": inviteeEmail,
            "status": InvitationStatus.pending.rawValue,
            "createdAt": Timestamp(date: Date()),
            "expiresAt": Timestamp(date: expiresAt),
            "code": code
        ]
        // Create the household document
        
        // Fix: Use proper completion handler
        db.collection("householdInvitations").addDocument(data: invitationData) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isProcessing = false
                
                if let error = error {
                    self.errorMessage = "Failed to create invitation: \(error.localizedDescription)"
                    completion(nil)
                } else {
                    // Return the invitation code
                    completion(code)
                }
            }
        }
    }
    
    func joinHouseholdWithCode(inviteCode: String, userId: String, displayName: String, email: String, completion: @escaping (String?) -> Void) {
        isProcessing = true
        errorMessage = nil
        
        // Find the invitation by code
        db.collection("householdInvitations")
            .whereField("code", isEqualTo: inviteCode)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        self.errorMessage = "Failed to find invitation: \(error.localizedDescription)"
                        completion(nil)
                    }
                    return
                }
                
                guard let document = snapshot?.documents.first,
                      let householdId = document.data()["householdId"] as? String,
                      let statusString = document.data()["status"] as? String,
                      let status = InvitationStatus(rawValue: statusString),
                      let expiresAtTimestamp = document.data()["expiresAt"] as? Timestamp else {
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        self.errorMessage = "Invalid invitation code"
                        completion(nil)
                    }
                    return
                }
                
                // Check if invitation is still valid
                if status != .pending {
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        self.errorMessage = "Invitation has already been \(status.rawValue.lowercased())"
                        completion(nil)
                    }
                    return
                }
                
                let expiresAt = expiresAtTimestamp.dateValue()
                if expiresAt < Date() {
                    // Update invitation status to expired
                    self.db.collection("householdInvitations").document(document.documentID)
                        .updateData(["status": InvitationStatus.expired.rawValue])
                    
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        self.errorMessage = "Invitation has expired"
                        completion(nil)
                    }
                    return
                }
                
                // Add user to household as a member
                let memberData: [String: Any] = [
                    "displayName": displayName,
                    "email": email,
                    "role": HouseholdRole.member.rawValue,
                    "joinedAt": Timestamp(date: Date()),
                    "profileImageURL": ""
                ]
                
                // First, add the user to the household members collection
                self.db.collection("households").document(householdId)
                    .collection("members").document(userId).setData(memberData) { error in
                        if let error = error {
                            DispatchQueue.main.async {
                                self.isProcessing = false
                                self.errorMessage = "Failed to add member: \(error.localizedDescription)"
                                completion(nil)
                            }
                            return
                        }
                        
                        // Update the household document to include this member ID
                        self.db.collection("households").document(householdId)
                            .updateData([
                                "memberIds": FieldValue.arrayUnion([userId])
                            ]) { error in
                                if let error = error {
                                    DispatchQueue.main.async {
                                        self.isProcessing = false
                                        self.errorMessage = "Failed to update household: \(error.localizedDescription)"
                                        completion(nil)
                                    }
                                    return
                                }
                                
                                // Update invitation status to accepted
                                self.db.collection("householdInvitations").document(document.documentID)
                                    .updateData(["status": InvitationStatus.accepted.rawValue])
                                
                                // Add the household to the user's households array and set as current
                                self.db.collection("users").document(userId)
                                    .updateData([
                                        "households": FieldValue.arrayUnion([householdId]),
                                        "currentHouseholdId": householdId
                                    ]) { error in
                                        DispatchQueue.main.async {
                                            self.isProcessing = false
                                            
                                            if let error = error {
                                                self.errorMessage = "Failed to update user: \(error.localizedDescription)"
                                                completion(nil)
                                            } else {
                                                completion(householdId)
                                            }
                                        }
                                    }
                            }
                    }
            }
    }
    
    func leaveHousehold(householdId: String, userId: String, completion: @escaping (Bool) -> Void) {
        isProcessing = true
        errorMessage = nil
        
        // Remove user from household members
        db.collection("households").document(householdId)
            .collection("members").document(userId).delete { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        self.errorMessage = "Failed to leave household: \(error.localizedDescription)"
                        completion(false)
                    }
                    return
                }
                
                // Remove household from user's households array
                self.db.collection("users").document(userId)
                    .updateData([
                        "households": FieldValue.arrayRemove([householdId])
                    ]) { error in
                        DispatchQueue.main.async {
                            self.isProcessing = false
                            
                            if let error = error {
                                self.errorMessage = "Failed to update user: \(error.localizedDescription)"
                                completion(false)
                            } else {
                                completion(true)
                            }
                        }
                    }
            }
    }
    
    func updateMemberRole(householdId: String, memberId: String, newRole: HouseholdRole, completion: @escaping (Bool) -> Void) {
        isProcessing = true
        errorMessage = nil
        
        db.collection("households").document(householdId)
            .collection("members").document(memberId)
            .updateData(["role": newRole.rawValue]) { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isProcessing = false
                    
                    if let error = error {
                        self.errorMessage = "Failed to update role: \(error.localizedDescription)"
                        completion(false)
                    } else {
                        self.fetchHouseholdMembers(householdId: householdId)
                        completion(true)
                    }
                }
            }
    }
    
    func removeMember(householdId: String, memberId: String, completion: @escaping (Bool) -> Void) {
        isProcessing = true
        errorMessage = nil
        
        // Remove user from household members
        db.collection("households").document(householdId)
            .collection("members").document(memberId).delete { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        self.errorMessage = "Failed to remove member: \(error.localizedDescription)"
                        completion(false)
                    }
                    return
                }
                
                // Remove household from user's households array
                self.db.collection("users").document(memberId)
                    .updateData([
                        "households": FieldValue.arrayRemove([householdId])
                    ]) { error in
                        DispatchQueue.main.async {
                            self.isProcessing = false
                            
                            if let error = error {
                                self.errorMessage = "Failed to update user: \(error.localizedDescription)"
                                completion(false)
                            } else {
                                self.fetchHouseholdMembers(householdId: householdId)
                                completion(true)
                            }
                        }
                    }
            }
    }
    
    func updateHouseholdName(householdId: String, newName: String, completion: @escaping (Bool) -> Void) {
        isProcessing = true
        errorMessage = nil
        
        db.collection("households").document(householdId)
            .updateData([
                "name": newName,
                "updatedAt": Timestamp(date: Date())
            ]) { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isProcessing = false
                    
                    if let error = error {
                        self.errorMessage = "Failed to update name: \(error.localizedDescription)"
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            }
    }
    
    func deleteHousehold(householdId: String, completion: @escaping (Bool) -> Void) {
        isProcessing = true
        errorMessage = nil
        
        // First, get all members to update their user documents
        db.collection("households").document(householdId)
            .collection("members").getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        self.errorMessage = "Failed to fetch members: \(error.localizedDescription)"
                        completion(false)
                    }
                    return
                }
                
                let batch = self.db.batch()
                
                // Update each user's households array
                for document in snapshot?.documents ?? [] {
                    let userId = document.documentID
                    let userRef = self.db.collection("users").document(userId)
                    batch.updateData([
                        "households": FieldValue.arrayRemove([householdId])
                    ], forDocument: userRef)
                }
                
                // Delete the household document
                let householdRef = self.db.collection("households").document(householdId)
                batch.deleteDocument(householdRef)
                
                // Commit the batch
                batch.commit { error in
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        
                        if let error = error {
                            self.errorMessage = "Failed to delete household: \(error.localizedDescription)"
                            completion(false)
                        } else {
                            completion(true)
                        }
                    }
                }
            }
    }
    
    func fetchHousehold(householdId: String, completion: (() -> Void)? = nil) {
        isProcessing = true
        
        db.collection("households").document(householdId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isProcessing = false
                
                if let error = error {
                    self.errorMessage = "Failed to fetch household: \(error.localizedDescription)"
                    completion?()
                    return
                }
                
                guard let data = snapshot?.data(),
                      let name = data["name"] as? String,
                      let createdAtTimestamp = data["createdAt"] as? Timestamp else {
                    self.errorMessage = "Invalid household data"
                    completion?()
                    return
                }
                
                self.household = Household(
                    id: householdId,
                    name: name,
                    createdAt: createdAtTimestamp.dateValue()
                )
                
                completion?()
            }
        }
        func updateHouseholdWithMemberIds(householdId: String, memberIds: [String]) {
            db.collection("households").document(householdId)
                .updateData([
                    "memberIds": memberIds
                ]) { error in
                    if let error = error {
                        print("Failed to update memberIds: \(error.localizedDescription)")
                    }
                }
        }
        func updateHouseholdMembers(householdId: String, userId: String) {
            db.collection("households").document(householdId)
                .updateData([
                    "memberIds": FieldValue.arrayUnion([userId])
                ]) { error in
                    if let error = error {
                        print("Failed to update memberIds: \(error.localizedDescription)")
                    } else {
                        print("Successfully updated household members")
                    }
                }
        }
        
    }
}
