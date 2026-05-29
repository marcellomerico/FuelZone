import SwiftUI

/// Central FuelZone design tokens (Amber dark theme).
enum DesignSystem {
    // MARK: - Colors

    static let accent = Color("AccentColor")
    static let accentLight = Color(red: 250 / 255, green: 199 / 255, blue: 117 / 255)
    static let accentOnAmber = Color(red: 65 / 255, green: 36 / 255, blue: 2 / 255)

    static let appBackground = Color.black
    static let cardSurface = Color(red: 20 / 255, green: 20 / 255, blue: 20 / 255)
    static let cardSurfaceSecondary = Color(red: 22 / 255, green: 22 / 255, blue: 22 / 255)
    static let embeddedTrack = Color(red: 12 / 255, green: 12 / 255, blue: 12 / 255)
    static let inactiveSegment = Color(red: 34 / 255, green: 34 / 255, blue: 34 / 255)

    static let textPrimary = Color.white
    static let textSecondary = Color(red: 136 / 255, green: 136 / 255, blue: 136 / 255)
    static let textTertiary = Color(red: 102 / 255, green: 102 / 255, blue: 102 / 255)

    static let sodiumAccent = Color(red: 133 / 255, green: 183 / 255, blue: 235 / 255)

    static let divider = Color.white.opacity(0.07)
    static let tabBarSurface = Color(red: 22 / 255, green: 22 / 255, blue: 22 / 255)
    static let tabInactive = Color(red: 119 / 255, green: 119 / 255, blue: 119 / 255)

    static var accentSoft: Color { accent.opacity(0.14) }
    static var groupedBackground: Color { appBackground }
    static var cardBackground: Color { cardSurface }

    // MARK: - Layout

    static let cardCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 12
    static let chipCornerRadius: CGFloat = 14
    static let sectionSpacing: CGFloat = 14
    static let cardPadding: CGFloat = 14
    static let compactSpacing: CGFloat = 8
    static let contentMaxWidth: CGFloat = 560

    // MARK: - Typography

    enum Typography {
        static let screenTitle = Font.system(size: 22, weight: .medium)
        static let sectionTitle = Font.system(size: 15, weight: .medium)
        static let cardTitle = Font.system(size: 14, weight: .medium)
        static let metricLarge = Font.system(size: 34, weight: .medium)
        static let metricValue = Font.system(size: 22, weight: .medium)
        static let metricUnit = Font.system(size: 13, weight: .regular)
        static let body = Font.system(size: 15, weight: .regular)
        static let bodySecondary = Font.system(size: 14, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)
        static let micro = Font.system(size: 11, weight: .regular)
    }

    // MARK: - Snack pills

    static func carbPillColors(grams: Int) -> (background: Color, foreground: Color) {
        switch grams {
        case ..<30:
            return (accentLight.opacity(0.18), accentLight)
        case ..<55:
            return (accent.opacity(0.22), accent)
        default:
            return (Color(red: 133 / 255, green: 79 / 255, blue: 11 / 255).opacity(0.38), accentLight)
        }
    }

    static var sodiumPillBackground: Color { sodiumAccent.opacity(0.16) }
}

// MARK: - Card & screen

struct CardStyle: ViewModifier {
    var padding: CGFloat = DesignSystem.cardPadding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(DesignSystem.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardCornerRadius, style: .continuous))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.cardTitle)
            .foregroundStyle(DesignSystem.accentOnAmber)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(DesignSystem.accent.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.buttonCornerRadius, style: .continuous))
    }
}

extension View {
    func fuelZoneCard(padding: CGFloat = DesignSystem.cardPadding) -> some View {
        modifier(CardStyle(padding: padding))
    }

    func fuelZoneScreenContent() -> some View {
        frame(maxWidth: DesignSystem.contentMaxWidth)
            .frame(maxWidth: .infinity)
    }
}
