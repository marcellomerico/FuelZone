import SwiftUI

struct OnboardingWelcomeStep: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)
            Text(localized: "onboarding.welcome.title")
                .font(.title.bold())
            Text(localized: "onboarding.tagline")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct OnboardingSportStep: View {
    @Binding var sport: SportType

    var body: some View {
        stepShell(title: "onboarding.sport.title", subtitle: "onboarding.sport.subtitle") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(SportType.allCases) { item in
                    Button {
                        sport = item
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: item.systemImageName)
                                .font(.title2)
                            Text(LocalizedEnum.label(for: item))
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(sport == item ? Color.accentColor.opacity(0.15) : DesignSystem.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct OnboardingStomachStep: View {
    @Binding var sensitivity: StomachSensitivity

    var body: some View {
        stepShell(title: "onboarding.stomach.title", subtitle: "onboarding.stomach.subtitle", tooltip: "onboarding.stomach.tooltip") {
            pickerList(selection: $sensitivity, cases: StomachSensitivity.allCases) { LocalizedEnum.label(for: $0) }
        }
    }
}

struct OnboardingSweatStep: View {
    @Binding var sweatRate: SweatRate

    var body: some View {
        stepShell(title: "onboarding.sweat.title", subtitle: "onboarding.sweat.subtitle", tooltip: "onboarding.sweat.tooltip") {
            pickerList(selection: $sweatRate, cases: SweatRate.allCases) { LocalizedEnum.label(for: $0) }
        }
    }
}

struct OnboardingSaltinessStep: View {
    @Binding var saltiness: SweatSaltiness

    var body: some View {
        stepShell(title: "onboarding.saltiness.title", subtitle: "onboarding.saltiness.subtitle", tooltip: "onboarding.saltiness.tooltip") {
            pickerList(selection: $saltiness, cases: SweatSaltiness.allCases) { LocalizedEnum.label(for: $0) }
        }
    }
}

struct OnboardingProfileStep: View {
    @Binding var name: String
    @Binding var weight: String
    @Binding var maxHR: String

    var body: some View {
        stepShell(title: "onboarding.profile.title", subtitle: "onboarding.ready.message") {
            TextField(String(localized: "onboarding.profile.name"), text: $name)
                .textFieldStyle(.roundedBorder)
            TextField(String(localized: "onboarding.profile.weight"), text: $weight)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
            TextField(String(localized: "session.zone.maxHR"), text: $maxHR)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct OnboardingReadyStep: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)
            Text(localized: "onboarding.ready.title")
                .font(.title.bold())
            Text(localized: "onboarding.ready.message")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Helpers

private func stepShell<Content: View>(
    title: String,
    subtitle: String,
    tooltip: String? = nil,
    @ViewBuilder content: () -> Content
) -> some View {
    VStack(alignment: .leading, spacing: 16) {
        Text(localized: title).font(.title2.bold())
        Text(localized: subtitle).foregroundStyle(.secondary)
        if let tooltip {
            Text(localized: tooltip).font(.caption).foregroundStyle(.secondary)
        }
        content()
        Spacer(minLength: 0)
    }
}

private func pickerList<T: Hashable & Identifiable>(
    selection: Binding<T>,
    cases: [T],
    label: @escaping (T) -> String
) -> some View {
    VStack(spacing: 8) {
        ForEach(cases) { item in
            Button { selection.wrappedValue = item } label: {
                HStack {
                    Text(label(item))
                    Spacer()
                    if selection.wrappedValue == item {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .padding()
                .background(DesignSystem.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}
