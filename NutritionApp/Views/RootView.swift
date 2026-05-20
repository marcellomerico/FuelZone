import SwiftUI

struct RootView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        MainTabView()
            .environmentObject(appState)
            .preferredColorScheme(colorScheme)
            .environment(\.locale, appLocale)
            .sheet(isPresented: $appState.showOnboarding) {
                OnboardingView(viewModel: appState.onboardingViewModel)
                    .environmentObject(appState)
                    .interactiveDismissDisabled()
            }
    }

    private var colorScheme: ColorScheme? {
        switch appState.settings.appearance {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    private var appLocale: Locale {
        switch appState.settings.language {
        case .system:
            return Locale.current
        case .english:
            return Locale(identifier: "en")
        case .german:
            return Locale(identifier: "de")
        }
    }
}
