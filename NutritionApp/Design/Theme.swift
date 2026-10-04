import SwiftUI

/// FuelZone design tokens – “Race Instrument”.
///
/// Rules: amber fills only the single primary action of a screen, selections are ink (black in light,
/// white in dark), and every nutrient keeps its colour everywhere (carbs amber, fluids blue, sodium teal).
/// All colours live in the asset catalog with light and dark variants (≥ 4.5:1 for text).
enum Theme {
    enum Colors {
        static let background = Color("FZBackground")
        static let surface = Color("FZSurface")
        static let surface2 = Color("FZSurface2")
        /// Raised element on `surface2` (selected segment).
        static let raised = Color("FZRaised")
        static let ink = Color("FZInk")
        static let ink2 = Color("FZInk2")
        static let ink3 = Color("FZInk3")
        static let onInk = Color("FZOnInk")
        static let line = Color("FZLine")
        static let accentFill = Color("FZAccentFill")
        static let onAccent = Color("FZOnAccent")
        static let accentText = Color("FZAccentText")
        static let danger = Color("FZDanger")
        static let success = Color("FZSuccess")
    }

    /// Nutrient colours: foreground for text/marks, tint for backgrounds behind that text.
    enum Nutrient: CaseIterable {
        case carbs, fluids, sodium

        var color: Color {
            switch self {
            case .carbs: Color("FZCarb")
            case .fluids: Color("FZFluid")
            case .sodium: Color("FZSalt")
            }
        }

        var tint: Color {
            switch self {
            case .carbs: Color("FZCarbTint")
            case .fluids: Color("FZFluidTint")
            case .sodium: Color("FZSaltTint")
            }
        }
    }

    enum Radius {
        static let control: CGFloat = 12
        static let tile: CGFloat = 16
        static let card: CGFloat = 22
        static let hero: CGFloat = 26
        static let button: CGFloat = 18
    }

    enum Spacing {
        static let screen: CGFloat = 20
        static let section: CGFloat = 16
        static let card: CGFloat = 16
        static let tight: CGFloat = 8
    }

    /// Minimum touch target (Apple HIG).
    static let minTouch: CGFloat = 44

    enum Typography {
        /// Screen titles: expanded, heavy.
        static let largeTitle = Font.system(.largeTitle, weight: .heavy).width(.expanded)
        static let title = Font.system(.title2, weight: .heavy).width(.expanded)
        static let sectionTitle = Font.system(.title3, weight: .heavy).width(.expanded)
        static let headline = Font.system(.headline, weight: .bold)
        static let body = Font.system(.body)
        static let bodyEmphasis = Font.system(.body, weight: .semibold)
        static let subheadline = Font.system(.subheadline)
        static let subheadlineEmphasis = Font.system(.subheadline, weight: .semibold)
        static let footnote = Font.system(.footnote, weight: .medium)
        static let caption = Font.system(.caption, weight: .semibold)
        /// Small caps label above sections ("DAUER", "INTENSITÄT").
        static let label = Font.system(.caption, weight: .bold)
        static let button = Font.system(.headline, weight: .heavy).width(.standard)
    }
}

// MARK: - Metric numbers

/// Compressed, heavy numerals like a race clock ("1:30", "50"). Scales with Dynamic Type.
struct MetricText: View {
    let text: String
    var size: CGFloat
    var color: Color = Theme.Colors.ink
    var relativeTo: Font.TextStyle = .largeTitle

    @ScaledMetric private var scale: CGFloat = 1

    init(_ text: String, size: CGFloat, color: Color = Theme.Colors.ink, relativeTo: Font.TextStyle = .largeTitle) {
        self.text = text
        self.size = size
        self.color = color
        self.relativeTo = relativeTo
        _scale = ScaledMetric(wrappedValue: 1, relativeTo: relativeTo)
    }

    var body: some View {
        Text(text)
            .font(.system(size: size * min(scale, 1.6), weight: .heavy).width(.compressed))
            .monospacedDigit()
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }
}

// MARK: - Modifiers

extension View {
    /// Card surface with the standard radius; a hairline shadow in light mode only.
    func fzCard(padding: CGFloat = Theme.Spacing.card, radius: CGFloat = Theme.Radius.card) -> some View {
        modifier(FZCardModifier(padding: padding, radius: radius))
    }

    /// Caps section label style.
    func fzLabelStyle() -> some View {
        font(Theme.Typography.label)
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(Theme.Colors.ink2)
    }

    /// Screen background that also covers the safe areas.
    func fzScreenBackground() -> some View {
        background(Theme.Colors.background.ignoresSafeArea())
    }
}

private struct FZCardModifier: ViewModifier {
    let padding: CGFloat
    let radius: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Theme.Colors.surface)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 1, y: 1)
            )
    }
}
