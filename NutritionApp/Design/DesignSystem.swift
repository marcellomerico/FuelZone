import SwiftUI

enum DesignSystem {
    static let cardCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 12
    static let sectionSpacing: CGFloat = 24
    static let cardPadding: CGFloat = 18
    static let compactSpacing: CGFloat = 10
    static let contentMaxWidth: CGFloat = 560

    static var groupedBackground: Color { Color(.systemGroupedBackground) }
    static var cardBackground: Color { Color(.secondarySystemGroupedBackground) }
    static var accentSoft: Color { Color.accentColor.opacity(0.12) }

    enum Typography {
        static let screenTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let sectionTitle = Font.system(.title3, design: .rounded).weight(.semibold)
        static let cardTitle = Font.system(.subheadline, design: .rounded).weight(.semibold)
        static let metricValue = Font.system(.title, design: .rounded).weight(.bold)
        static let metricUnit = Font.system(.caption, design: .rounded).weight(.medium)
        static let body = Font.system(.body, design: .default)
        static let bodySecondary = Font.system(.subheadline, design: .default)
        static let caption = Font.system(.caption, design: .default)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DesignSystem.cardPadding)
            .background(DesignSystem.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardCornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.cardTitle)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.accentColor.opacity(configuration.isPressed ? 0.85 : 1))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.buttonCornerRadius, style: .continuous))
    }
}

extension View {
    func fuelZoneCard() -> some View { modifier(CardStyle()) }

    func fuelZoneScreenContent() -> some View {
        frame(maxWidth: DesignSystem.contentMaxWidth)
            .frame(maxWidth: .infinity)
    }
}
