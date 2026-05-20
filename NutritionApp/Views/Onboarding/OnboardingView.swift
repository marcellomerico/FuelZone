import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.sectionSpacing) {
                ProgressView(value: Double(viewModel.stepIndex + 1), total: Double(viewModel.totalSteps))
                    .tint(Color.accentColor)
                    .padding(.horizontal)

                stepContent
                    .frame(maxHeight: .infinity)

                navigationBar
            }
            .padding()
            .background(DesignSystem.groupedBackground)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.stepIndex {
        case 0: OnboardingWelcomeStep()
        case 1: OnboardingSportStep(sport: $viewModel.primarySport)
        case 2: OnboardingStomachStep(sensitivity: $viewModel.stomachSensitivity)
        case 3: OnboardingSweatStep(sweatRate: $viewModel.sweatRate)
        case 4: OnboardingSaltinessStep(saltiness: $viewModel.sweatSaltiness)
        case 5: OnboardingProfileStep(
            name: $viewModel.displayName,
            weight: $viewModel.weightText,
            maxHR: $viewModel.maxHeartRateText
        )
        default: OnboardingReadyStep()
        }
    }

    private var navigationBar: some View {
        HStack {
            if viewModel.stepIndex > 0 {
                Button { viewModel.back() } label: {
                    Text(localized: "onboarding.button.back")
                }
            }
            Spacer()
            Button {
                if viewModel.stepIndex < viewModel.totalSteps - 1 {
                    viewModel.next()
                } else {
                    appState.completeOnboarding()
                }
            } label: {
                Text(localized: viewModel.stepIndex < viewModel.totalSteps - 1
                     ? "onboarding.button.next" : "onboarding.button.start")
                    .fontWeight(.semibold)
            }
        }
    }
}
