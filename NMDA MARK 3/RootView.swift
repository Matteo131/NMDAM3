//
//  RootView.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 21/04/2025.
//
// Correct version of RootView.swift
import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    
    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView(isCompleted: $hasSeenOnboarding)
            } else if authViewModel.isAuthenticated {
                if let householdId = authViewModel.currentHouseholdId {
                    EnhancedMainTabView(householdId: householdId)
                } else {
                    EnhancedHouseholdSetupView()
                }
            } else {
                LoginView()
            }
        }
    }
}
