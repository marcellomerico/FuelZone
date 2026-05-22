import Combine
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var profile: UserProfile
    @Published var settings: AppSettings
    @Published var showOnboarding: Bool
    @Published var selectedTab: Int = 0

    let subscriptionManager = SubscriptionManager()
    let sessionViewModel: SessionViewModel
    let resultsViewModel: ResultsViewModel
    let snackViewModel: SnackViewModel
    let historyViewModel: HistoryViewModel
    let onboardingViewModel: OnboardingViewModel

    private let store = DataStore.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        let loadedProfile = DataStore.shared.load(UserProfile.self, key: PersistenceKeys.userProfile)
            ?? UserProfile()
        let loadedSettings = DataStore.shared.load(AppSettings.self, key: PersistenceKeys.appSettings)
            ?? AppSettings()

        profile = loadedProfile
        settings = loadedSettings
        showOnboarding = !loadedProfile.hasCompletedOnboarding

        snackViewModel = SnackViewModel()
        historyViewModel = HistoryViewModel()
        sessionViewModel = SessionViewModel()
        resultsViewModel = ResultsViewModel()
        onboardingViewModel = OnboardingViewModel()

        onboardingViewModel.configure(profile: loadedProfile)
        sessionViewModel.configure(
            profile: loadedProfile,
            settings: loadedSettings,
            snacks: snackViewModel,
            results: resultsViewModel
        )
        resultsViewModel.configure(settings: loadedSettings, snacks: snackViewModel)
        historyViewModel.configure(settings: loadedSettings)
        snackViewModel.configure(settings: loadedSettings)

        bindSubscriptionStatus()
        observeCloudSync()

        Task {
            await store.syncFromCloudKit()
            await subscriptionManager.loadProducts()
        }
    }

    private func bindSubscriptionStatus() {
        subscriptionManager.$isProActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                guard let self, self.settings.isProSubscriber != isActive else { return }
                self.settings.isProSubscriber = isActive
                self.applySettingsToViewModels()
                self.store.save(self.settings, key: PersistenceKeys.appSettings)
            }
            .store(in: &cancellables)
    }

    private func observeCloudSync() {
        NotificationCenter.default.publisher(for: .dataStoreDidSyncFromCloud)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reloadFromStore() }
            .store(in: &cancellables)
    }

    func reloadFromStore() {
        if let p = store.load(UserProfile.self, key: PersistenceKeys.userProfile) { profile = p }
        if let s = store.load(AppSettings.self, key: PersistenceKeys.appSettings) {
            settings = s
            applySettingsToViewModels()
        }
        snackViewModel.reload()
        historyViewModel.reload()
    }

    func saveProfile() {
        store.save(profile, key: PersistenceKeys.userProfile)
        sessionViewModel.updateProfile(profile)
    }

    func saveSettings() {
        store.save(settings, key: PersistenceKeys.appSettings)
        applySettingsToViewModels()
    }

    private func applySettingsToViewModels() {
        sessionViewModel.updateSettings(settings)
        resultsViewModel.updateSettings(settings)
        historyViewModel.updateSettings(settings)
        snackViewModel.configure(settings: settings)
    }

    func completeOnboarding() {
        profile = onboardingViewModel.buildProfile()
        profile.hasCompletedOnboarding = true
        saveProfile()
        showOnboarding = false
        sessionViewModel.updateProfile(profile)
    }

    func syncNow() {
        Task { await store.syncFromCloudKit() }
    }
}
