import SwiftUI

struct SimpleAchievementsView: View {
    let householdId: String
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "house.fill")
                .font(.system(size: 70))
                .foregroundColor(AppTheme.primaryColor)
                .padding()
            
            Text("Household Stats")
                .font(AppTheme.titleFont)
            
            Text("Track your household's activity and progress.")
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("Coming Soon")
                .font(AppTheme.headlineFont)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppTheme.primaryColor.opacity(0.1))
                .foregroundColor(AppTheme.primaryColor)
                .cornerRadius(AppTheme.cornerRadius)
                .padding(.top, 16)
        }
        .padding()
        .navigationTitle("Household Stats")
    }
}
