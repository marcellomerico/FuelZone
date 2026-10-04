import SwiftUI

struct RootView: View {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        MainTabView()
            .environmentObject(appState)
            .tint(DesignSystem.accent)
            .preferredColorScheme(colorScheme)
            .environment(\.locale, appLocale)
            .id(appState.store.settings.language.rawValue + appLocale.identifier)
            .sheet(isPresented: $appState.showOnboarding) {
                OnboardingView(viewModel: appState.onboardingViewModel)
                    .environmentObject(appState)
                    .interactiveDismissDisabled()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { appState.appDidBecomeActive() }
            }
    }

    private var colorScheme: ColorScheme? {
        switch appState.store.settings.appearance {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    private var appLocale: Locale {
        switch appState.store.settings.language {
        case .system:
            return Locale.current
        case .english:
            return Locale(identifier: "en")
        case .german:
            return Locale(identifier: "de")
        }
    }
}
