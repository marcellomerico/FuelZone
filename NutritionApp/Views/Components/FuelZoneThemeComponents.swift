import SwiftUI

// MARK: - Segmented control

struct FuelZoneSegmentedPicker<Selection: Hashable>: View {
    let options: [(Selection, String)]
    @Binding var selection: Selection

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.0) { option, titleKey in
                Button {
                    selection = option
                } label: {
                    Text(localized: titleKey)
                        .font(DesignSystem.Typography.bodySecondary)
                        .foregroundStyle(
                            selection == option ? DesignSystem.accentOnAmber : DesignSystem.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            selection == option ? DesignSystem.accent : DesignSystem.inactiveSegment
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Pills

struct FuelZonePill: View {
    let text: String
    let background: Color
    let foreground: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(foreground)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

// MARK: - Fuel preview (Plan tab)

struct FuelZonePlanPreviewCard: View {
    let carbsPerHour: Int
    let gelCount: Int
    let sodiumPerHour: Int
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(DesignSystem.accent)
                Text(localized: "results.title")
                    .font(DesignSystem.Typography.caption.weight(.medium))
                    .foregroundStyle(DesignSystem.accentLight)
            }

            HStack(spacing: 0) {
                previewMetric(value: "\(carbsPerHour)", unit: "g", labelKey: "results.perHour")
                previewDivider
                previewMetric(value: gelCountLabel, unit: "", labelKey: "category.gel")
                previewDivider
                previewMetric(value: "\(sodiumPerHour)", unit: "mg", labelKey: "results.sodium")
            }

            Button(action: action) {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(DesignSystem.accentOnAmber)
                    } else {
                        Text(localized: "session.calculate")
                    }
                }
                .font(DesignSystem.Typography.cardTitle)
                .foregroundStyle(DesignSystem.accentOnAmber)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)
            .background(DesignSystem.accent)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.buttonCornerRadius, style: .continuous))
            .disabled(isLoading)
        }
        .padding(15)
        .background(
            LinearGradient(
                colors: [Color(red: 31 / 255, green: 20 / 255, blue: 7 / 255), Color(red: 42 / 255, green: 26 / 255, blue: 8 / 255)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cardCornerRadius, style: .continuous)
                .stroke(DesignSystem.accent.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardCornerRadius, style: .continuous))
    }

    private var gelCountLabel: String {
        gelCount > 0 ? "≈\(gelCount)" : "—"
    }

    private var previewDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(width: 1)
            .padding(.vertical, 4)
    }

    private func previewMetric(value: String, unit: String, labelKey: String) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(DesignSystem.Typography.metricValue)
                    .foregroundStyle(DesignSystem.textPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(DesignSystem.Typography.metricUnit)
                        .foregroundStyle(DesignSystem.textSecondary)
                }
            }
            Text(localized: labelKey)
                .font(DesignSystem.Typography.micro)
                .foregroundStyle(DesignSystem.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Duration slider

struct FuelZoneDurationSlider: View {
    @Binding var minutes: Int
    var range: ClosedRange<Int> = 30...300

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(minutes)")
                    .font(DesignSystem.Typography.metricLarge)
                    .foregroundStyle(DesignSystem.textPrimary)
                    .monospacedDigit()
                Text(localized: "session.duration.minutes")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.textSecondary)
            }

            Slider(
                value: Binding(
                    get: { Double(minutes) },
                    set: { minutes = Int($0.rounded()) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(DesignSystem.accent)
        }
    }
}

// MARK: - Snack row

struct FuelZoneSnackRowStyled: View {
    let snack: Snack
    var photo: UIImage?
    var isEnabled: Bool
    var onToggle: (Bool) -> Void
    var onTap: (() -> Void)?

    private var carbGrams: Int { Int(snack.carbsPerDefaultPortion.rounded()) }
    private var sodiumMg: Int { Int(snack.sodiumMgPerDefaultPortion.rounded()) }
    private var carbColors: (background: Color, foreground: Color) {
        DesignSystem.carbPillColors(grams: carbGrams)
    }

    var body: some View {
        HStack(spacing: 11) {
            snackIcon

            VStack(alignment: .leading, spacing: 5) {
                Text(snack.localizedName)
                    .font(DesignSystem.Typography.cardTitle)
                    .foregroundStyle(DesignSystem.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    FuelZonePill(
                        text: L10n.format("snack.pill.carbs", "\(carbGrams)"),
                        background: carbColors.background,
                        foreground: carbColors.foreground
                    )
                    FuelZonePill(
                        text: L10n.format("snack.pill.sodium", "\(sodiumMg)"),
                        background: DesignSystem.sodiumPillBackground,
                        foreground: DesignSystem.sodiumAccent
                    )
                }
            }

            Spacer(minLength: 0)

            Toggle("", isOn: Binding(get: { isEnabled }, set: onToggle))
                .labelsHidden()
                .tint(DesignSystem.accent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }

    @ViewBuilder
    private var snackIcon: some View {
        Group {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: snack.category.systemImageName)
                    .font(.system(size: 18))
                    .foregroundStyle(carbColors.foreground)
            }
        }
        .frame(width: 40, height: 40)
        .background(carbColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .clipped()
    }
}

// MARK: - Filter chips

struct FuelZoneSnackFilterChips: View {
    @Binding var selectedCategory: SnackCategory?

    private let chips: [(SnackCategory?, String)] = [
        (nil, "snack.library.all"),
        (.gel, "category.gel"),
        (.drink, "category.drink"),
        (.solid, "category.solid")
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(chips, id: \.1) { category, key in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(localized: key)
                            .font(.system(size: 12, weight: selectedCategory == category ? .medium : .regular))
                            .foregroundStyle(
                                selectedCategory == category ? DesignSystem.accentOnAmber : DesignSystem.textSecondary
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                selectedCategory == category ? DesignSystem.accent : DesignSystem.cardSurfaceSecondary
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - History empty state

struct FuelZoneHistoryEmptyState: View {
    let onCreatePlan: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)

            ZStack {
                Circle()
                    .fill(DesignSystem.accent.opacity(0.1))
                    .frame(width: 96, height: 96)
                Circle()
                    .fill(DesignSystem.accent.opacity(0.16))
                    .frame(width: 64, height: 64)
                Image(systemName: "flame.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(DesignSystem.accent)
            }
            .padding(.bottom, 22)

            Text(localized: "history.empty.title")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(DesignSystem.textPrimary)
                .padding(.bottom, 8)

            Text(localized: "history.empty")
                .font(DesignSystem.Typography.bodySecondary)
                .foregroundStyle(DesignSystem.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

            Button(action: onCreatePlan) {
                Label {
                    Text(localized: "onboarding.button.start")
                } icon: {
                    Image(systemName: "plus")
                }
                .font(DesignSystem.Typography.cardTitle)
                .foregroundStyle(DesignSystem.accentOnAmber)
                .padding(.horizontal, 26)
                .padding(.vertical, 12)
                .background(DesignSystem.accent)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Settings profile row

struct FuelZoneProfileCard: View {
    let titleKey: String
    let subtitleKey: String
    let initials: String

    var body: some View {
        HStack(spacing: 13) {
            Text(initials)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(DesignSystem.accent)
                .frame(width: 48, height: 48)
                .background(DesignSystem.accentSoft)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(localized: titleKey)
                    .font(DesignSystem.Typography.sectionTitle)
                    .foregroundStyle(DesignSystem.textPrimary)
                Text(localized: subtitleKey)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.textSecondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DesignSystem.textTertiary)
        }
        .fuelZoneCard()
    }
}

// MARK: - Pro marketing card

struct FuelZoneProCard: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    let isProActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 9) {
                Image(systemName: "star.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(DesignSystem.accentOnAmber)
                    .frame(width: 30, height: 30)
                    .background(DesignSystem.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                Text(localized: "settings.pro.title")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DesignSystem.textPrimary)
            }

            Text(localized: "settings.pro.subtitle")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.accentLight.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            if isProActive {
                FuelZoneInfoBanner(message: String(localized: "storekit.status.active"), style: .success)
            } else {
                FuelZoneSubscriptionOptions(
                    subscriptionManager: subscriptionManager,
                    showsLegalDisclaimer: true
                )
            }
        }
        .padding(15)
        .background(
            LinearGradient(
                colors: [Color(red: 42 / 255, green: 26 / 255, blue: 8 / 255), Color(red: 28 / 255, green: 18 / 255, blue: 6 / 255)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cardCornerRadius, style: .continuous)
                .stroke(DesignSystem.accent.opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardCornerRadius, style: .continuous))
    }
}

// MARK: - Floating tab bar

struct FuelZoneFloatingTabBar: View {
    @Binding var selection: Int

    private struct TabItem {
        let tag: Int
        let titleKey: String
        let icon: String
    }

    private let items: [TabItem] = [
        TabItem(tag: 0, titleKey: "tab.plan", icon: "flame.fill"),
        TabItem(tag: 1, titleKey: "tab.history", icon: "clock.fill"),
        TabItem(tag: 2, titleKey: "tab.snacks", icon: "fork.knife"),
        TabItem(tag: 3, titleKey: "tab.settings", icon: "gearshape.fill")
    ]

    var body: some View {
        HStack {
            ForEach(items, id: \.tag) { item in
                Button {
                    selection = item.tag
                } label: {
                    VStack(spacing: 1) {
                        Image(systemName: item.icon)
                            .font(.system(size: 19))
                        Text(localized: item.titleKey)
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(selection == item.tag ? DesignSystem.accent : DesignSystem.tabInactive)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(DesignSystem.tabBarSurface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
}
