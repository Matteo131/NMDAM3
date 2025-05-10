//
//  AuthViewModel.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 14/04/2025.
//
import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var currentHouseholdId: String?
    
    init() {
        configureAuthStateListener()
    }
    
    func configureAuthStateListener() {
            Auth.auth().addStateDidChangeListener { [weak self] _, user in
                guard let self = self else { return }
                self.isAuthenticated = user != nil
                self.user = user
                
                if let user = user {
                    // Check if user has a current household
                    self.fetchUserData(userId: user.uid)
                } else {
                    self.currentHouseholdId = nil
                }
            }
        }
        
        func fetchUserData(userId: String) {
            Firestore.firestore().collection("users").document(userId).getDocument { [weak self] document, error in
                guard let self = self, let document = document, document.exists else {
                    return
                }
                
                // Get current household ID from user data
                if let householdId = document.data()?["currentHouseholdId"] as? String {
                    self.currentHouseholdId = householdId
                }
            }
        }
    

    func signIn(email: String, password: String) {
        isProcessing = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            self.isProcessing = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            
            if let user = result?.user {
                self.fetchUserHousehold(userId: user.uid)
            }
        }
    }
    
    func signUp(email: String, password: String, displayName: String) {
        isProcessing = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isProcessing = false
                self.errorMessage = error.localizedDescription
                return
            }
            
            guard let user = result?.user else {
                self.isProcessing = false
                self.errorMessage = "Failed to create account"
                return
            }
            
            // Update user profile
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            
            changeRequest.commitChanges { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isProcessing = false
                    return
                }
                
                // Create user document in Firestore
                let userData: [String: Any] = [
                    "displayName": displayName,
                    "email": email,
                    "createdAt": Timestamp(date: Date()),
                    "households": []
                ]
                
                Firestore.firestore().collection("users").document(user.uid).setData(userData) { error in
                    self.isProcessing = false
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func fetchUserHousehold(userId: String) {
        Firestore.firestore().collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self, let document = document, document.exists else {
                return
            }
            
            if let households = document.data()?["households"] as? [String], !households.isEmpty {
                self.currentHouseholdId = households[0]
            }
        }
    }
}
