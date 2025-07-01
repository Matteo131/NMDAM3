import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct AppTheme {
    // MARK: - Colors
    static let primaryColor = Color(hex: "4A80F0")    // Blue
    static let secondaryColor = Color(hex: "3CC8AA")  // Teal
    static let accentColor = Color(hex: "F59762")     // Orange
    static let errorColor = Color(hex: "F55E5E")      // Red
    static let successColor = Color(hex: "4CD964")    // Green
    static let warningColor = Color(hex: "FAD02C")    // Yellow
    static let dangerColor = Color(hex: "FF5252")     // Bright Red
    static let infoColor = Color(hex: "3182CE")       // Information blue
    
    static let backgroundLight = Color(hex: "F9FAFB")
    static let backgroundMedium = Color(hex: "F3F4F6")
    static let cardShadow: Color = Color.black.opacity(0.05)
    static let shadowRadius: CGFloat = 6
    
    // Text colors
    static let textPrimary = Color(hex: "1A1D29")     // Darker for better contrast
    static let textSecondary = Color(hex: "4A5568")   // Better contrast ratio
    static let textTertiary = Color(hex: "718096")    // Still readable but subtle
    
    // MARK: - Typography
    static let largeTitleFont = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let titleFont = Font.system(.title, design: .rounded).weight(.bold)
    static let title2Font = Font.system(.title2, design: .rounded).weight(.bold)
    static let title3Font = Font.system(.title3, design: .rounded).weight(.semibold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
    static let subheadlineFont = Font.system(.subheadline, design: .rounded).weight(.medium)
    static let bodyFont = Font.system(.body, design: .rounded)
    static let bodyBoldFont = Font.system(.body, design: .rounded).weight(.semibold)
    static let calloutFont = Font.system(.callout, design: .rounded)
    static let captionFont = Font.system(.caption, design: .rounded)
    static let caption2Font = Font.system(.caption2, design: .rounded)
    
    // Specialized fonts
    static let numberFont = Font.system(.title2, design: .monospaced).weight(.bold)
    static let buttonFont = Font.system(.callout, design: .rounded).weight(.semibold)
    static let badgeFont = Font.system(.caption, design: .rounded).weight(.bold)
    
    // MARK: - Spacing
    static let microSpacing: CGFloat = 4
    static let smallSpacing: CGFloat = 8
    static let spacing: CGFloat = 16
    static let mediumSpacing: CGFloat = 24
    static let largeSpacing: CGFloat = 32
    static let xLargeSpacing: CGFloat = 48
    
    // MARK: - Sizing
    static let minTouchTarget: CGFloat = 44  // iOS HIG minimum
    static let buttonHeight: CGFloat = 48    // Comfortable for students
    static let cardMinHeight: CGFloat = 80   // Minimum card height
    static let iconSize: CGFloat = 24        // Standard icon size
    static let largeIconSize: CGFloat = 32   // For emphasis
    static let cornerRadius: CGFloat = 12
    
    // MARK: - Shadows
    static let shadowColor: Color = Color.black.opacity(0.05)
    
    // MARK: - Gradients
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [backgroundLight, backgroundMedium]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Helper Methods
    static func emptyState(
        icon: String,
        message: String,
        buttonText: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 24) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Self.primaryColor.opacity(0.2), Self.primaryColor.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(Self.primaryColor)
            }
            .shadow(color: Self.primaryColor.opacity(0.2), radius: 20, x: 0, y: 10)
            
            Text(message)
                .font(Self.subheadlineFont)
                .foregroundColor(Self.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: action) {
                Text(buttonText)
                    .font(Self.subheadlineFont)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Self.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(Self.cornerRadius)
                    .shadow(color: Self.primaryColor.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
        .padding()
    }
}

// MARK: - View Modifiers
extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.white)
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(color: AppTheme.cardShadow, radius: AppTheme.shadowRadius, x: 0, y: 2)
    }
    
    func primaryButton() -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppTheme.primaryColor)
            .foregroundColor(.white)
            .cornerRadius(AppTheme.cornerRadius)
    }
    
    func secondaryButton() -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .foregroundColor(AppTheme.primaryColor)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.primaryColor, lineWidth: 1)
            )
    }
}
