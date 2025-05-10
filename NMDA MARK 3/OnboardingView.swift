import SwiftUI

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @State private var currentPage = 0
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundColor(.white)
                    .padding()
                }
                
                // Page indicator
                HStack(spacing: 12) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                
                // Onboarding pages
                TabView(selection: $currentPage) {
                    OnboardingPageView(
                        image: "house.fill",
                        title: "Welcome to NMDA",
                        description: "The ultimate app to manage your shared living experience with roommates."
                    ).tag(0)
                    
                    OnboardingPageView(
                        image: "list.bullet.clipboard",
                        title: "Organize Tasks",
                        description: "Easily manage chores, groceries, and expenses with your roommates."
                    ).tag(1)
                    
                    OnboardingPageView(
                        image: "calendar",
                        title: "Stay in Sync",
                        description: "Coordinate events, bills, and more with your household."
                    ).tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: UIScreen.main.bounds.height * 0.6)
                
                // Continue button
                Button(action: {
                    if currentPage < 2 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                }) {
                    HStack {
                        Text(currentPage < 2 ? "Continue" : "Get Started")
                            .fontWeight(.bold)
                        
                        Image(systemName: "arrow.right")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .foregroundColor(AppTheme.primaryColor)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        isCompleted = true
    }
}

struct OnboardingPageView: View {
    let image: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: image)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .foregroundColor(.white)
                .padding(.bottom, 20)
            
            Text(title)
                .font(AppTheme.titleFont)
                .foregroundColor(.white)
            
            Text(description)
                .font(AppTheme.bodyFont)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 32)
        }
    }
}
