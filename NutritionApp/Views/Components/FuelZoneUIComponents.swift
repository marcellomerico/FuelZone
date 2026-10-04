import SwiftUI
import UIKit

// MARK: - Screen layout

struct FuelZoneScreenScroll<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.sectionSpacing) {
                content()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
            .fuelZoneScreenContent()
        }
        .background(DesignSystem.appBackground)
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
                .foregroundStyle(DesignSystem.accent)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let titleKey {
                Text(localized: titleKey)
                    .font(DesignSystem.Typography.sectionTitle)
                    .foregroundStyle(DesignSystem.textPrimary)
            }
            if let subtitleKey {
                Text(localized: subtitleKey)
                    .font(DesignSystem.Typography.bodySecondary)
                    .foregroundStyle(DesignSystem.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .fuelZoneCard()
    }
}

struct FuelZoneSectionHeader: View {
    let titleKey: String
    var subtitleKey: String?
    var systemImage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(localized: titleKey)
                .font(DesignSystem.Typography.sectionTitle)
                .foregroundStyle(DesignSystem.textPrimary)
            if let subtitleKey {
                Text(localized: subtitleKey)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.textSecondary)
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
                .foregroundStyle(DesignSystem.accent)
                .padding(.top, 7)
            Text(localized: textKey)
                .font(DesignSystem.Typography.bodySecondary)
                .foregroundStyle(DesignSystem.textPrimary)
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
                .foregroundStyle(DesignSystem.accent)
                .frame(width: 32, height: 32)
                .background(DesignSystem.accentSoft)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(localized: titleKey)
                    .font(DesignSystem.Typography.cardTitle)
                    .foregroundStyle(DesignSystem.textPrimary)
                Text(localized: bodyKey)
                    .font(DesignSystem.Typography.bodySecondary)
                    .foregroundStyle(DesignSystem.textSecondary)
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
            case .info: DesignSystem.accent
            case .warning: DesignSystem.accentLight
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
                .foregroundStyle(DesignSystem.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignSystem.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.tint.opacity(0.1))
        .clipShape(
            RoundedRectangle(cornerRadius: DesignSystem.cardCornerRadius, style: .continuous))
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
                    .foregroundStyle(DesignSystem.accent)
                Text(localized: durationKey)
                    .font(DesignSystem.Typography.cardTitle)
                    .foregroundStyle(DesignSystem.textPrimary)
                Spacer()
                Text(localized: amountKey)
                    .font(DesignSystem.Typography.metricValue)
                    .foregroundStyle(DesignSystem.accent)
            }
            Text(localized: tipKey)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.textSecondary)
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
                .foregroundStyle(DesignSystem.accent)
                .frame(width: 28, height: 28)
                .background(DesignSystem.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(localized: titleKey)
                    .font(DesignSystem.Typography.cardTitle)
                    .foregroundStyle(DesignSystem.textPrimary)
                if let subtitleKey {
                    Text(localized: subtitleKey)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.textSecondary)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DesignSystem.textTertiary)
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
                    .foregroundStyle(DesignSystem.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DesignSystem.accent)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(DesignSystem.embeddedTrack)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct FuelZoneSnackRow: View {
    let snack: Snack
    var photo: UIImage?
    var showsToggle: Bool = false
    var isEnabled: Bool = false
    var onToggle: ((Bool) -> Void)?
    var onTap: (() -> Void)?

    var body: some View {
        FuelZoneSnackRowStyled(
            snack: snack,
            photo: photo,
            isEnabled: isEnabled,
            onToggle: { onToggle?($0) },
            onTap: onTap
        )
    }
}

struct FuelZoneCardDivider: View {
    var body: some View {
        Rectangle()
            .fill(DesignSystem.divider)
            .frame(height: 0.5)
            .padding(.horizontal, 12)
    }
}

struct FuelZoneTextButton: View {
    let titleKey: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(localized: titleKey)
                .font(DesignSystem.Typography.bodySecondary.weight(.medium))
                .foregroundStyle(DesignSystem.accent)
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
                .foregroundStyle(DesignSystem.textSecondary)
            TextField("", text: $text)
                .keyboardType(keyboardType)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(DesignSystem.embeddedTrack)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

/// Compact section label for settings pickers.
struct FuelZoneSettingsLabel: View {
    let titleKey: String

    var body: some View {
        Text(localized: titleKey)
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.textSecondary)
    }
}
