import SwiftUI

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @State private var currentPage = 0
    @EnvironmentObject var authViewModel: AuthViewModel
    
    private let pages = [
        OnboardingPage(
            title: "Never Forget Anything Again",
            subtitle: "End the sticky note chaos",
            description: "Keep track of chores, groceries, bills, and events all in one place. No more \"I thought you were buying milk\" moments.",
            icon: "house.fill",
            color: AppTheme.primaryColor,
            benefits: ["✓ All household tasks in one app", "✓ Real-time updates for everyone", "✓ Never miss important deadlines"]
        ),
        OnboardingPage(
            title: "No More Awkward Money Conversations",
            subtitle: "Split bills fairly, automatically",
            description: "Track who paid for what and settle up easily. Remove the stress from shared expenses and focus on what matters.",
            icon: "dollarsign.circle.fill",
            color: AppTheme.successColor,
            benefits: ["✓ Automatic expense splitting", "✓ Clear payment tracking", "✓ End money-related conflicts"]
        ),
        OnboardingPage(
            title: "Stay Coordinated, Stay Sane",
            subtitle: "One household, one system",
            description: "Share calendars, coordinate grocery runs, and keep everyone in the loop. Perfect for busy student life.",
            icon: "calendar.badge.plus",
            color: AppTheme.accentColor,
            benefits: ["✓ Shared household calendar", "✓ Coordinated grocery shopping", "✓ Instant household updates"]
        )
    ]
    
    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    AppTheme.primaryColor,
                    AppTheme.secondaryColor,
                    AppTheme.accentColor
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.trailing, 24)
                    .padding(.top, 16)
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Bottom section
                VStack(spacing: 24) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(currentPage == index ? Color.white : Color.white.opacity(0.4))
                                .frame(width: currentPage == index ? 32 : 8, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        if currentPage > 0 {
                            Button("Back") {
                                withAnimation(.easeInOut) {
                                    currentPage -= 1
                                }
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 80)
                        } else {
                            Spacer()
                                .frame(width: 80)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if currentPage < pages.count - 1 {
                                withAnimation(.easeInOut) {
                                    currentPage += 1
                                }
                            } else {
                                completeOnboarding()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                                    .font(.system(size: 18, weight: .semibold))
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(AppTheme.primaryColor)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(25)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        withAnimation(.easeInOut) {
            isCompleted = true
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let color: Color
    let benefits: [String]
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon with enhanced styling
            ZStack {
                // Background glow
                Circle()
                    .fill(page.color.opacity(0.3))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)
                
                // Main circle
                Circle()
                    .fill(.white.opacity(0.25))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.3), lineWidth: 2)
                    )
                
                // Icon
                Image(systemName: page.icon)
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(page.subtitle)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }
            
            // Benefits list with better styling
            VStack(alignment: .leading, spacing: 12) {
                ForEach(page.benefits, id: \.self) { benefit in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        
                        Text(benefit)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
            
            Spacer()
        }
        .padding(.vertical, 40)
    }
}
