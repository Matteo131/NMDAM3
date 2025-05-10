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
    // Simplified color palette
    static let primaryColor = Color(hex: "4A80F0")    // Blue
    static let secondaryColor = Color(hex: "3CC8AA")  // Teal
    static let accentColor = Color(hex: "F59762")     // Orange
    static let errorColor = Color(hex: "F55E5E")      // Red
    static let successColor = Color(hex: "4CD964")    // Green
    static let warningColor = Color(hex: "FAD02C")    // Yellow
    static let dangerColor = Color(hex: "FF5252")     // Bright Red
    
    // Background colors
    static let backgroundLight = Color(hex: "F9FAFB")
    static let backgroundMedium = Color(hex: "F3F4F6")
    
    // Text colors
    static let textPrimary = Color(hex: "121826")     // Near black
    static let textSecondary = Color(hex: "646E82")   // Medium gray
    static let textTertiary = Color(hex: "9AA4B8")    // Light gray
    
    // Fonts
    static let titleFont = Font.system(.title3, design: .rounded).bold()
    static let headlineFont = Font.system(.headline, design: .rounded)
    static let subheadlineFont = Font.system(.subheadline, design: .rounded)
    static let bodyFont = Font.system(.body, design: .rounded)
    static let captionFont = Font.system(.caption, design: .rounded)
    
    // Sizing
    static let cornerRadius: CGFloat = 12
    static let spacing: CGFloat = 16
    static let smallSpacing: CGFloat = 8
    
    // Shadows
    static let cardShadow: Color = Color.black.opacity(0.05)
    static let shadowRadius: CGFloat = 6
    
    // Background gradient
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [backgroundLight, backgroundMedium]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Empty state helper
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

// Common View Modifiers
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
