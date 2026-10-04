import SwiftUI

struct OnboardingWelcomeStep: View {
    var body: some View {
        FuelZoneHeroBlock(
            systemImage: "flame.fill",
            titleKey: "onboarding.welcome.title",
            subtitleKey: "onboarding.tagline"
        )
    }
}

struct OnboardingSportStep: View {
    @Binding var sport: SportType

    var body: some View {
        stepShell(
            titleKey: "onboarding.sport.title",
            subtitleKey: "onboarding.sport.subtitle",
            systemImage: "sportscourt"
        ) {
            SportSelectionGrid(selection: $sport)
        }
    }
}

struct OnboardingStomachStep: View {
    @Binding var sensitivity: StomachSensitivity

    var body: some View {
        stepShell(
            titleKey: "onboarding.stomach.title",
            subtitleKey: "onboarding.stomach.subtitle",
            tooltipKey: "onboarding.stomach.tooltip",
            systemImage: "leaf.fill"
        ) {
            pickerList(selection: $sensitivity, cases: StomachSensitivity.allCases) { LocalizedEnum.label(for: $0) }
        }
    }
}

struct OnboardingSweatStep: View {
    @Binding var sweatRate: SweatRate

    var body: some View {
        stepShell(
            titleKey: "onboarding.sweat.title",
            subtitleKey: "onboarding.sweat.subtitle",
            tooltipKey: "onboarding.sweat.tooltip",
            systemImage: "drop.fill"
        ) {
            pickerList(selection: $sweatRate, cases: SweatRate.allCases) { LocalizedEnum.label(for: $0) }
        }
    }
}

struct OnboardingSaltinessStep: View {
    @Binding var saltiness: SweatSaltiness

    var body: some View {
        stepShell(
            titleKey: "onboarding.saltiness.title",
            subtitleKey: "onboarding.saltiness.subtitle",
            tooltipKey: "onboarding.saltiness.tooltip",
            systemImage: "bolt.fill"
        ) {
            pickerList(selection: $saltiness, cases: SweatSaltiness.allCases) { LocalizedEnum.label(for: $0) }
        }
    }
}

struct OnboardingProfileStep: View {
    @Binding var name: String
    @Binding var weight: String
    @Binding var maxHR: String

    var body: some View {
        stepShell(
            titleKey: "onboarding.profile.title",
            subtitleKey: "onboarding.profile.subtitle",
            systemImage: "person.fill"
        ) {
            FuelZoneLabeledField(labelKey: "onboarding.profile.name", text: $name, keyboardType: .default)
            FuelZoneLabeledField(labelKey: "onboarding.profile.weight", text: $weight)
            FuelZoneLabeledField(labelKey: "session.zone.maxHR", text: $maxHR, keyboardType: .numberPad)
        }
    }
}

// MARK: - Helpers

private func stepShell<Content: View>(
    titleKey: String,
    subtitleKey: String,
    tooltipKey: String? = nil,
    systemImage: String,
    @ViewBuilder content: () -> Content
) -> some View {
    VStack(alignment: .leading, spacing: 16) {
        FuelZoneSectionHeader(titleKey: titleKey, subtitleKey: subtitleKey, systemImage: systemImage)
        if let tooltipKey {
            Text(localized: tooltipKey)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.textSecondary)
        }
        content()
    }
    .fuelZoneCard()
}

private func pickerList<T: Hashable & Identifiable>(
    selection: Binding<T>,
    cases: [T],
    label: @escaping (T) -> String
) -> some View {
    VStack(spacing: 8) {
        ForEach(cases) { item in
            FuelZoneSelectionRow(
                title: label(item),
                isSelected: selection.wrappedValue == item
            ) {
                selection.wrappedValue = item
            }
        }
    }
}
