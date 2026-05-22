import SwiftUI

// MARK: - Screen layout (matches Science & Methodology)

/// Standard scroll screen: grouped background, padding, max width.
struct FuelZoneScreenScroll<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.sectionSpacing) {
                content()
            }
            .padding()
            .fuelZoneScreenContent()
        }
        .background(DesignSystem.groupedBackground)
    }
}

struct FuelZoneHeroBlock: View {
    let systemImage: String
    var titleKey: String?
    var subtitleKey: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let titleKey {
                Text(localized: titleKey)
                    .font(DesignSystem.Typography.sectionTitle)
            }
            if let subtitleKey {
                Text(localized: subtitleKey)
                    .font(DesignSystem.Typography.bodySecondary)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .fuelZoneCard()
    }
}

/// Section title with optional SF Symbol — used across plan, results, and settings content.
struct FuelZoneSectionHeader: View {
    let titleKey: String
    var subtitleKey: String?
    var systemImage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 28, height: 28)
                        .background(DesignSystem.accentSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                Text(localized: titleKey)
                    .font(DesignSystem.Typography.sectionTitle)
                    .foregroundStyle(.primary)
            }
            if let subtitleKey {
                Text(localized: subtitleKey)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct FuelZoneBulletRow: View {
    let textKey: String
    var systemImage: String = "circle.fill"

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 6))
                .foregroundStyle(Color.accentColor)
                .padding(.top, 7)
            Text(localized: textKey)
                .font(DesignSystem.Typography.bodySecondary)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct FuelZoneNumberedStep: View {
    let number: Int
    let titleKey: String
    let bodyKey: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(DesignSystem.Typography.cardTitle)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32, height: 32)
                .background(DesignSystem.accentSoft)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(localized: titleKey)
                    .font(DesignSystem.Typography.cardTitle)
                Text(localized: bodyKey)
                    .font(DesignSystem.Typography.bodySecondary)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct FuelZoneInfoBanner: View {
    let message: String
    var style: Style = .info

    enum Style {
        case info, warning, success

        var icon: String {
            switch self {
            case .info: "info.circle.fill"
            case .warning: "exclamationmark.triangle.fill"
            case .success: "checkmark.circle.fill"
            }
        }

        var tint: Color {
            switch self {
            case .info: .accentColor
            case .warning: .orange
            case .success: .green
            }
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: style.icon)
                .foregroundStyle(style.tint)
                .font(.title3)
            Text(message)
                .font(DesignSystem.Typography.bodySecondary)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignSystem.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.tint.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardCornerRadius, style: .continuous))
    }
}

struct FuelZoneDurationTierCard: View {
    let durationKey: String
    let amountKey: String
    let tipKey: String
    var icon: String = "flame.fill"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Color.accentColor)
                Text(localized: durationKey)
                    .font(DesignSystem.Typography.cardTitle)
                Spacer()
                Text(localized: amountKey)
                    .font(DesignSystem.Typography.metricValue)
                    .foregroundStyle(Color.accentColor)
            }
            Text(localized: tipKey)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .fuelZoneCard()
    }
}

struct FuelZoneNavigationRow: View {
    let titleKey: String
    var subtitleKey: String?
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 28, height: 28)
                .background(DesignSystem.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(localized: titleKey)
                    .font(DesignSystem.Typography.cardTitle)
                    .foregroundStyle(.primary)
                if let subtitleKey {
                    Text(localized: subtitleKey)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct FuelZoneSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(DesignSystem.Typography.bodySecondary)
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct FuelZoneSnackRow: View {
    let snack: Snack
    var showsToggle: Bool = false
    var isEnabled: Bool = false
    var onToggle: ((Bool) -> Void)?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: snack.category.systemImageName)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 40, height: 40)
                .background(DesignSystem.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(snack.localizedName)
                    .font(DesignSystem.Typography.cardTitle)
                Text(NutritionMetricsFormatting.snackMacros(
                    carbs: Int(snack.carbsPerServing),
                    sodium: Int(snack.sodiumMgPerServing)
                ))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if showsToggle, let onToggle {
                Toggle("", isOn: Binding(get: { isEnabled }, set: onToggle))
                    .labelsHidden()
            }
        }
        .padding(.vertical, 6)
    }
}

struct FuelZoneCardDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 54)
    }
}

struct FuelZoneTextButton: View {
    let titleKey: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(localized: titleKey)
                .font(DesignSystem.Typography.bodySecondary.weight(.medium))
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

struct FuelZoneLabeledField: View {
    let labelKey: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .decimalPad

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(localized: labelKey)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)
            TextField("", text: $text)
                .keyboardType(keyboardType)
                .font(DesignSystem.Typography.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}
