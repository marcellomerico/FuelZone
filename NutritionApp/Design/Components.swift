import SwiftUI

// MARK: - Buttons

/// The one amber action of a screen.
struct FZPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.button)
            .foregroundStyle(Theme.Colors.onAccent)
            .frame(maxWidth: .infinity, minHeight: 54)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                    .fill(Theme.Colors.accentFill)
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.45)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

/// Neutral secondary action on a surface with a hairline border.
struct FZSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.bodyEmphasis)
            .foregroundStyle(Theme.Colors.ink)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.Colors.surface)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.Colors.line))
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// Round icon button (44 pt), e.g. back, share, add.
struct FZIconButtonStyle: ButtonStyle {
    var filled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(filled ? Theme.Colors.onInk : Theme.Colors.ink)
            .frame(width: Theme.minTouch, height: Theme.minTouch)
            .background(
                Circle()
                    .fill(filled ? Theme.Colors.ink : Theme.Colors.surface)
                    .overlay(Circle().stroke(filled ? Color.clear : Theme.Colors.line))
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == FZPrimaryButtonStyle {
    static var fzPrimary: FZPrimaryButtonStyle { FZPrimaryButtonStyle() }
}

extension ButtonStyle where Self == FZSecondaryButtonStyle {
    static var fzSecondary: FZSecondaryButtonStyle { FZSecondaryButtonStyle() }
}

// MARK: - Selection

/// Pill chip; selected chips are ink (never amber).
struct FZChip: View {
    let title: String
    var systemImage: String?
    let isSelected: Bool
    var height: CGFloat = Theme.minTouch
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage).font(.subheadline.weight(.semibold))
                }
                Text(title).font(Theme.Typography.subheadlineEmphasis)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: height)
            .foregroundStyle(isSelected ? Theme.Colors.onInk : Theme.Colors.ink)
            .background(
                Capsule().fill(isSelected ? Theme.Colors.ink : Theme.Colors.surface)
                    .overlay(Capsule().stroke(isSelected ? Color.clear : Theme.Colors.line))
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Compact segmented control with a raised neutral thumb (iOS-like, not amber).
struct FZSegmentedControl<Value: Hashable>: View {
    struct Option {
        let value: Value
        let title: String
        var badge: String?
    }

    let options: [Option]
    @Binding var selection: Value
    var onSelect: ((Value) -> Bool)?

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.value) { option in
                let isSelected = option.value == selection
                Button {
                    if onSelect?(option.value) ?? true {
                        withAnimation(.snappy(duration: 0.2)) { selection = option.value }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(option.title)
                            .font(isSelected ? Theme.Typography.caption.weight(.heavy) : Theme.Typography.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        if let badge = option.badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(Theme.Colors.accentText)
                        }
                    }
                    .foregroundStyle(isSelected ? Theme.Colors.ink : Theme.Colors.ink2)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 32)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(isSelected ? Theme.Colors.raised : Color.clear)
                            .shadow(color: .black.opacity(isSelected ? 0.12 : 0), radius: 1.5, y: 1)
                    )
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Capsule().fill(Theme.Colors.surface2))
    }
}

/// Large selectable tile (intensity, plan option). Selected tiles are ink-filled.
struct FZSelectableTile<Content: View>: View {
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let content: (Bool) -> Content

    var body: some View {
        Button(action: action) {
            content(isSelected)
                .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
                .padding(12)
                .foregroundStyle(isSelected ? Theme.Colors.onInk : Theme.Colors.ink)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous)
                        .fill(isSelected ? Theme.Colors.ink : Theme.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous)
                                .stroke(isSelected ? Color.clear : Theme.Colors.line)
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Three rising bars that show effort (1–3 filled).
struct EffortBars: View {
    let level: Int
    var onInk = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < level ? fill : empty)
                    .frame(width: 7, height: CGFloat(10 + index * 7))
            }
        }
        .accessibilityHidden(true)
    }

    private var fill: Color { onInk ? Theme.Colors.onInk : Theme.Colors.ink }
    private var empty: Color { onInk ? Theme.Colors.onInk.opacity(0.3) : Theme.Colors.surface2 }
}

// MARK: - Labels & tiles

struct FZSectionHeader: View {
    let title: String
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Theme.Typography.sectionTitle)
                .foregroundStyle(Theme.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            if let trailing {
                Text(trailing)
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Colors.ink2)
            }
        }
    }
}

/// Large screen header: small caps eyebrow over an expanded title.
struct FZScreenHeader<Trailing: View>: View {
    let eyebrow: String?
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                if let eyebrow {
                    Text(eyebrow).fzLabelStyle()
                }
                Text(title)
                    .font(Theme.Typography.largeTitle)
                    .foregroundStyle(Theme.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer(minLength: 0)
            trailing()
        }
    }
}

extension FZScreenHeader where Trailing == EmptyView {
    init(eyebrow: String?, title: String) {
        self.init(eyebrow: eyebrow, title: title, trailing: { EmptyView() })
    }
}

/// Rounded square with an icon on a tinted background.
struct FZIconTile: View {
    let systemImage: String
    var foreground: Color = Theme.Colors.ink
    var background: Color = Theme.Colors.surface2
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: size * 0.32, style: .continuous).fill(background))
            .accessibilityHidden(true)
    }
}

/// Small coloured pill for a planned item ("1 Gel", "150 ml Iso").
struct FZDataToken: View {
    let text: String
    let systemImage: String
    let nutrient: Theme.Nutrient

    var body: some View {
        Label {
            Text(text).font(Theme.Typography.caption.weight(.bold))
        } icon: {
            Image(systemName: systemImage).font(.caption.weight(.bold))
        }
        .labelStyle(.titleAndIcon)
        .foregroundStyle(nutrient.color)
        .padding(.horizontal, 10)
        .frame(minHeight: 32)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(nutrient.tint))
    }
}

/// Value + unit + caption, coloured by nutrient (dock, tiles, history rows).
struct FZMetric: View {
    let value: String
    let unit: String
    let caption: String
    var color: Color = Theme.Colors.ink
    var size: CGFloat = 32

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                MetricText(value, size: size, color: color, relativeTo: .title)
                Text(unit)
                    .font(Theme.Typography.caption.weight(.bold))
                    .foregroundStyle(color)
            }
            Text(caption)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.Colors.ink2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Meters

/// Horizontal meter: grey track, highlighted target band and a marker for the planned value.
struct FZRangeMeter: View {
    let range: ClosedRange<Double>
    let target: ClosedRange<Double>
    let value: Double
    let nutrient: Theme.Nutrient
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Colors.surface2)
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(nutrient.tint)
                    .overlay(RoundedRectangle(cornerRadius: height / 2).stroke(nutrient.color, lineWidth: 1.5))
                    .frame(width: max(height, width * fraction(target.upperBound) - width * fraction(target.lowerBound)))
                    .offset(x: width * fraction(target.lowerBound))
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Theme.Colors.ink)
                    .frame(width: 3, height: height + 6)
                    .offset(x: width * fraction(value) - 1.5)
            }
        }
        .frame(height: height + 6)
        .accessibilityHidden(true)
    }

    private func fraction(_ x: Double) -> CGFloat {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return CGFloat(min(max((x - range.lowerBound) / span, 0), 1))
    }
}

/// Carb tier scale (0 · 30 · 60 · 90 g/h) with the recommended band and the planned value.
struct CarbTierMeter: View {
    let target: NutritionRange
    let planned: Double
    private let maxValue = 100.0
    private let tiers: [Double] = [30, 60, 90]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .leading) {
                FZRangeMeter(
                    range: 0...maxValue,
                    target: target.min...max(target.min + 1, target.max),
                    value: planned,
                    nutrient: .carbs,
                    height: 12
                )
                GeometryReader { proxy in
                    ForEach(tiers, id: \.self) { tier in
                        Rectangle()
                            .fill(Theme.Colors.surface)
                            .frame(width: 2, height: 12)
                            .offset(x: proxy.size.width * tier / maxValue - 1, y: 3)
                    }
                }
                .allowsHitTesting(false)
            }
            .frame(height: 18)
            GeometryReader { proxy in
                ZStack(alignment: .topLeading) {
                    tierLabel("0", at: 0, width: proxy.size.width)
                    tierLabel(L10n.format("tier.short", "30"), at: 30, width: proxy.size.width)
                    tierLabel(L10n.format("tier.medium", "60"), at: 60, width: proxy.size.width)
                    tierLabel(L10n.format("tier.long", "90"), at: 90, width: proxy.size.width)
                }
            }
            .frame(height: 16)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.format(
            "a11y.carbMeter", "\(Int(planned.rounded()))", "\(Int(target.min))", "\(Int(target.max))"
        )))
    }

    private func tierLabel(_ text: String, at value: Double, width: CGFloat) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Theme.Colors.ink3)
            .fixedSize()
            .offset(x: width * value / maxValue)
    }
}

// MARK: - Glass dock & tab-like bars

/// Floating glass container (blur material) used for the plan dock.
struct FZGlassPanel<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Theme.Colors.line))
                    .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
            )
    }
}

// MARK: - Inputs

/// Labelled text field with an optional unit suffix; the label is also the accessibility label.
struct FZTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var unit: String?
    var keyboard: UIKeyboardType = .default
    var isInvalid = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.ink2)
            HStack(spacing: 8) {
                TextField(label, text: $text, prompt: Text(placeholder).foregroundStyle(Theme.Colors.ink3))
                    .keyboardType(keyboard)
                    .accessibilityLabel(Text(label))
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.ink)
                if let unit {
                    Text(unit)
                        .font(Theme.Typography.subheadlineEmphasis)
                        .foregroundStyle(Theme.Colors.ink2)
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: Theme.minTouch + 4)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.Colors.surface2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isInvalid ? Theme.Colors.danger : Color.clear, lineWidth: 1.5)
                    )
            )
        }
    }
}

/// Banner for info / warnings / success inside a screen.
struct FZBanner: View {
    enum Style { case info, warning, success }
    let message: String
    var style: Style = .info

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(message)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(tint))
    }

    private var icon: String {
        switch style {
        case .info: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .success: "checkmark.circle.fill"
        }
    }

    private var color: Color {
        switch style {
        case .info: Theme.Colors.accentText
        case .warning: Theme.Colors.accentText
        case .success: Theme.Colors.success
        }
    }

    private var tint: Color {
        switch style {
        case .info, .warning: Theme.Nutrient.carbs.tint
        case .success: Theme.Colors.success.opacity(0.12)
        }
    }
}
