import SwiftUI

struct RootView: View {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        MainTabView()
            .environmentObject(appState)
            .preferredColorScheme(colorScheme)
            .environment(\.locale, appLocale)
            .id(appState.store.settings.language.rawValue + appLocale.identifier)
            .fullScreenCover(isPresented: $appState.showOnboarding) {
                OnboardingView(viewModel: appState.onboardingViewModel)
                    .environmentObject(appState)
                    .preferredColorScheme(colorScheme)
                    .environment(\.locale, appLocale)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { appState.appDidBecomeActive() }
            }
    }

    private var colorScheme: ColorScheme? {
        #if DEBUG
        // UI tests / screenshots: `-FZForceAppearance light|dark`.
        switch UserDefaults.standard.string(forKey: "FZForceAppearance") {
        case "light": return .light
        case "dark": return .dark
        default: break
        }
        #endif
        switch appState.store.settings.appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
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
