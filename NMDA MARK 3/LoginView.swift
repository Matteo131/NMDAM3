//
//  LoginView.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 14/04/2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Logo and app name
            VStack(spacing: 16) {
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("NMDA")
                    .font(.largeTitle)
                    .bold()
                
                Text("Roommate Management")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 40)
            
            // Form fields
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            // Error message if any
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            // Login button
            Button(action: {
                authViewModel.signIn(email: email, password: password)
            }) {
                if authViewModel.isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Sign In")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .disabled(email.isEmpty || password.isEmpty || authViewModel.isProcessing)
            
            // Sign up link
            Button(action: {
                showingSignUp = true
            }) {
                Text("Don't have an account? ")
                    .foregroundColor(.secondary)
                +
                Text("Sign Up")
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
            }
            .padding(.top, 16)
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
    }
}

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var passwordsMatch = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("PERSONAL INFORMATION")) {
                    TextField("Full Name", text: $name)
                        .autocapitalization(.words)
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section(header: Text("PASSWORD")) {
                    SecureField("Password", text: $password)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .onChange(of: confirmPassword) { newValue in
                            passwordsMatch = password == newValue || newValue.isEmpty
                        }
                    
                    if !passwordsMatch {
                        Text("Passwords do not match")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                if let errorMessage = authViewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: {
                        if validateForm() {
                            authViewModel.signUp(email: email, password: password, displayName: name)
                        }
                    }) {
                        if authViewModel.isProcessing {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("Create Account")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                    .disabled(!isFormValid() || authViewModel.isProcessing)
                }
            }
            .navigationTitle("Create Account")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private func isFormValid() -> Bool {
        return !name.isEmpty && !email.isEmpty && !password.isEmpty &&
               !confirmPassword.isEmpty && passwordsMatch && password.count >= 6
    }
    
    private func validateForm() -> Bool {
        passwordsMatch = password == confirmPassword
        return isFormValid()
    }
}
