import SwiftUI

/// Four-step onboarding: welcome, main sport, body, optional details.
struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            progress
                .padding(.horizontal, Theme.Spacing.screen)
                .padding(.top, 16)

            ScrollView {
                Group {
                    switch viewModel.stepIndex {
                    case 0: WelcomeStep()
                    case 1: SportStep(sport: $viewModel.primarySport)
                    case 2: BodyStep(viewModel: viewModel)
                    default: DetailsStep(viewModel: viewModel)
                    }
                }
                .padding(Theme.Spacing.screen)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                .id(viewModel.stepIndex)
            }
            .scrollDismissesKeyboard(.interactively)

            controls
                .padding(.horizontal, Theme.Spacing.screen)
                .padding(.bottom, 12)
        }
        .fzScreenBackground()
        .animation(.snappy, value: viewModel.stepIndex)
    }

    private var progress: some View {
        HStack(spacing: 6) {
            ForEach(0..<viewModel.totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= viewModel.stepIndex ? Theme.Colors.ink : Theme.Colors.surface2)
                    .frame(height: 4)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text(L10n.format("onboarding.progress", "\(viewModel.stepIndex + 1)", "\(viewModel.totalSteps)")))
    }

    private var controls: some View {
        VStack(spacing: 8) {
            Button {
                if viewModel.isLastStep {
                    appState.completeOnboarding()
                } else {
                    viewModel.next()
                }
            } label: {
                HStack(spacing: 10) {
                    Text(localized: viewModel.isLastStep ? "onboarding.button.start" : "onboarding.button.next")
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(.fzPrimary)
            .accessibilityIdentifier("onboarding.primary")

            if viewModel.stepIndex > 0 {
                Button { viewModel.back() } label: {
                    Text(localized: "onboarding.button.back")
                        .font(Theme.Typography.subheadlineEmphasis)
                        .foregroundStyle(Theme.Colors.ink2)
                        .frame(maxWidth: .infinity, minHeight: Theme.minTouch)
                }
            } else {
                Text(localized: "onboarding.duration")
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Colors.ink2)
                    .frame(minHeight: Theme.minTouch)
            }
        }
    }
}

// MARK: - Steps

private struct WelcomeStep: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            CourseIllustration()
                .frame(height: 280)

            Text(localized: "onboarding.tagline")
                .font(.system(.largeTitle, weight: .heavy).width(.expanded))
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 12) {
                benefit("flame.fill", "onboarding.benefit.grams", .carbs)
                benefit("clock", "onboarding.benefit.timeline", nil)
                benefit("drop.fill", "onboarding.benefit.weather", .fluids)
            }
        }
    }

    private func benefit(_ icon: String, _ key: String, _ nutrient: Theme.Nutrient?) -> some View {
        HStack(spacing: 12) {
            FZIconTile(
                systemImage: icon,
                foreground: nutrient?.color ?? Theme.Colors.ink,
                background: nutrient?.tint ?? Theme.Colors.surface2,
                size: 36
            )
            Text(localized: key)
                .font(Theme.Typography.bodyEmphasis)
                .foregroundStyle(Theme.Colors.ink)
        }
    }
}

/// Course profile with fuel markers – the welcome illustration.
private struct CourseIllustration: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Theme.Colors.surface)
                HStack(spacing: 0) {
                    ForEach(0..<6, id: \.self) { _ in
                        Rectangle().fill(Theme.Colors.line).frame(width: 1)
                        Spacer()
                    }
                }
                .padding(.leading, w / 6)
                course(w: w, h: h, closed: true).fill(Theme.Colors.surface2)
                course(w: w, h: h, closed: false).stroke(Theme.Colors.ink, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                marker("0:20", icon: "bolt.fill", fill: Theme.Colors.accentFill, text: Theme.Colors.onAccent, dot: Theme.Colors.accentFill)
                    .position(x: w * 0.29, y: h * 0.55)
                marker("0:40", icon: "drop.fill", fill: Theme.Nutrient.fluids.tint, text: Theme.Nutrient.fluids.color, dot: Theme.Nutrient.fluids.color)
                    .position(x: w * 0.52, y: h * 0.45)
                marker("1:00", icon: "bolt.fill", fill: Theme.Colors.accentFill, text: Theme.Colors.onAccent, dot: Theme.Colors.accentFill)
                    .position(x: w * 0.76, y: h * 0.2)
                VStack(alignment: .leading, spacing: 0) {
                    MetricText("60", size: 64, color: Theme.Nutrient.carbs.color)
                    Text(localized: "onboarding.illustration.caption")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Nutrient.carbs.color)
                }
                .padding(18)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .accessibilityHidden(true)
    }

    private func course(w: CGFloat, h: CGFloat, closed: Bool) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: h * 0.79))
            path.addCurve(to: CGPoint(x: w * 0.25, y: h * 0.63), control1: CGPoint(x: w * 0.11, y: h * 0.77), control2: CGPoint(x: w * 0.15, y: h * 0.65))
            path.addCurve(to: CGPoint(x: w * 0.49, y: h * 0.59), control1: CGPoint(x: w * 0.35, y: h * 0.61), control2: CGPoint(x: w * 0.40, y: h * 0.71))
            path.addCurve(to: CGPoint(x: w * 0.75, y: h * 0.35), control1: CGPoint(x: w * 0.58, y: h * 0.47), control2: CGPoint(x: w * 0.63, y: h * 0.32))
            path.addCurve(to: CGPoint(x: w, y: h * 0.44), control1: CGPoint(x: w * 0.87, y: h * 0.38), control2: CGPoint(x: w * 0.94, y: h * 0.48))
            if closed {
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.closeSubpath()
            }
        }
    }

    private func marker(_ time: String, icon: String, fill: Color, text: Color, dot: Color) -> some View {
        VStack(spacing: 6) {
            Label(time, systemImage: icon)
                .font(.caption.weight(.heavy))
                .foregroundStyle(text)
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(fill))
            Circle().fill(dot)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Theme.Colors.surface, lineWidth: 3))
        }
    }
}

private struct SportStep: View {
    @Binding var sport: SportType

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepHeader(titleKey: "onboarding.sport.title", subtitleKey: "onboarding.sport.subtitle")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(SportType.allCases) { item in
                    FZSelectableTile(isSelected: sport == item) {
                        sport = item
                    } content: { _ in
                        VStack(alignment: .leading, spacing: 10) {
                            Image(systemName: item.systemImageName).font(.title2.weight(.semibold))
                            Spacer(minLength: 0)
                            Text(LocalizedEnum.label(for: item)).font(Theme.Typography.bodyEmphasis)
                        }
                    }
                }
            }
        }
    }
}

private struct BodyStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepHeader(titleKey: "onboarding.body.title", subtitleKey: "onboarding.body.subtitle")
            question(titleKey: "onboarding.stomach.title", hintKey: "onboarding.stomach.tooltip") {
                FZSegmentedControl(
                    options: StomachSensitivity.allCases.map { .init(value: $0, title: LocalizedEnum.label(for: $0)) },
                    selection: $viewModel.stomachSensitivity
                )
            }
            question(titleKey: "onboarding.sweat.title", hintKey: "onboarding.sweat.tooltip") {
                FZSegmentedControl(
                    options: SweatRate.allCases.map { .init(value: $0, title: LocalizedEnum.label(for: $0)) },
                    selection: $viewModel.sweatRate
                )
            }
            question(titleKey: "onboarding.saltiness.title", hintKey: "onboarding.saltiness.tooltip") {
                FZSegmentedControl(
                    options: SweatSaltiness.allCases.map { .init(value: $0, title: LocalizedEnum.label(for: $0)) },
                    selection: $viewModel.sweatSaltiness
                )
            }
        }
    }

    private func question<Control: View>(titleKey: String, hintKey: String, @ViewBuilder control: () -> Control) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localized: titleKey).font(Theme.Typography.headline).foregroundStyle(Theme.Colors.ink)
            control()
            Text(localized: hintKey)
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .fzCard()
    }
}

private struct DetailsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepHeader(titleKey: "onboarding.profile.title", subtitleKey: "onboarding.profile.subtitle")
            VStack(alignment: .leading, spacing: 12) {
                FZTextField(label: L10n.string("onboarding.profile.name"), text: $viewModel.displayName, placeholder: L10n.string("profile.name.placeholder"))
                    .textContentType(.givenName)
                FZTextField(
                    label: L10n.string("onboarding.profile.weight"), text: $viewModel.weightText, placeholder: "70",
                    unit: "kg", keyboard: .decimalPad,
                    isInvalid: !viewModel.weightText.isEmpty && InputParsing.weightKg(viewModel.weightText) == nil
                )
                FZTextField(
                    label: L10n.string("session.zone.maxHR"), text: $viewModel.maxHeartRateText, placeholder: "188",
                    unit: "bpm", keyboard: .numberPad,
                    isInvalid: !viewModel.maxHeartRateText.isEmpty && InputParsing.maxHeartRate(viewModel.maxHeartRateText) == nil
                )
                Text(localized: "onboarding.profile.maxHRHint")
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Colors.ink2)
                if viewModel.hasInvalidOptionalInput {
                    FZBanner(message: L10n.string("onboarding.profile.invalidHint"), style: .warning)
                }
            }
            .fzCard()
        }
    }
}

private func stepHeader(titleKey: String, subtitleKey: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(localized: titleKey)
            .font(Theme.Typography.largeTitle)
            .foregroundStyle(Theme.Colors.ink)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
        Text(localized: subtitleKey)
            .font(Theme.Typography.body)
            .foregroundStyle(Theme.Colors.ink2)
            .fixedSize(horizontal: false, vertical: true)
    }
}
