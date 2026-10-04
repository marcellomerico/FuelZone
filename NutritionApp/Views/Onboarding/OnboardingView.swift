import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: Double(viewModel.stepIndex + 1), total: Double(viewModel.totalSteps))
                    .tint(DesignSystem.accent)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                ScrollView {
                    stepContent
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                        .fuelZoneScreenContent()
                }

                navigationBar
                    .padding(16)
                    .background(DesignSystem.cardSurface)
            }
            .background(DesignSystem.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignSystem.appBackground, for: .navigationBar)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.stepIndex {
        case 0: OnboardingWelcomeStep()
        case 1: OnboardingSportStep(sport: $viewModel.primarySport)
        case 2:
            VStack(spacing: DesignSystem.sectionSpacing) {
                OnboardingStomachStep(sensitivity: $viewModel.stomachSensitivity)
                OnboardingSweatStep(sweatRate: $viewModel.sweatRate)
                OnboardingSaltinessStep(saltiness: $viewModel.sweatSaltiness)
            }
        default:
            OnboardingProfileStep(
                name: $viewModel.displayName,
                weight: $viewModel.weightText,
                maxHR: $viewModel.maxHeartRateText
            )
        }
    }

    private var navigationBar: some View {
        HStack {
            if viewModel.stepIndex > 0 {
                FuelZoneTextButton(titleKey: "onboarding.button.back") {
                    viewModel.back()
                }
                .frame(width: 100, alignment: .leading)
            }
            Spacer()
            if viewModel.stepIndex < viewModel.totalSteps - 1 {
                Button { viewModel.next() } label: {
                    Text(localized: "onboarding.button.next")
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 160)
            } else {
                Button { appState.completeOnboarding() } label: {
                    Text(localized: "onboarding.button.start")
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 200)
            }
        }
    }
}
