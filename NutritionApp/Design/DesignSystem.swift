import SwiftUI
import UIKit

/// Central FuelZone design tokens (Amber dark theme).
enum DesignSystem {
    // MARK: - Colors

    static let accent = Color("AccentColor")
    static let accentLight = Color(red: 250 / 255, green: 199 / 255, blue: 117 / 255)
    static let accentOnAmber = Color(red: 65 / 255, green: 36 / 255, blue: 2 / 255)

    static let appBackground = adaptive(light: .white, dark: .black)
    static let cardSurface = adaptive(
        light: UIColor(red: 245 / 255, green: 245 / 255, blue: 246 / 255, alpha: 1),
        dark: UIColor(red: 20 / 255, green: 20 / 255, blue: 20 / 255, alpha: 1)
    )
    static let cardSurfaceSecondary = adaptive(
        light: UIColor(red: 237 / 255, green: 237 / 255, blue: 239 / 255, alpha: 1),
        dark: UIColor(red: 22 / 255, green: 22 / 255, blue: 22 / 255, alpha: 1)
    )
    static let embeddedTrack = adaptive(
        light: UIColor(red: 227 / 255, green: 227 / 255, blue: 229 / 255, alpha: 1),
        dark: UIColor(red: 12 / 255, green: 12 / 255, blue: 12 / 255, alpha: 1)
    )
    static let inactiveSegment = adaptive(
        light: UIColor(red: 222 / 255, green: 222 / 255, blue: 224 / 255, alpha: 1),
        dark: UIColor(red: 34 / 255, green: 34 / 255, blue: 34 / 255, alpha: 1)
    )

    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    static let textTertiary = Color(uiColor: .tertiaryLabel)

    static let sodiumAccent = Color(red: 133 / 255, green: 183 / 255, blue: 235 / 255)

    static let divider = adaptive(
        light: UIColor.black.withAlphaComponent(0.09),
        dark: UIColor.white.withAlphaComponent(0.07)
    )
    static let tabBarSurface = adaptive(
        light: UIColor(red: 236 / 255, green: 236 / 255, blue: 238 / 255, alpha: 1),
        dark: UIColor(red: 22 / 255, green: 22 / 255, blue: 22 / 255, alpha: 1)
    )
    static let tabInactive = adaptive(
        light: UIColor(red: 94 / 255, green: 94 / 255, blue: 96 / 255, alpha: 1),
        dark: UIColor(red: 119 / 255, green: 119 / 255, blue: 119 / 255, alpha: 1)
    )

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

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
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
