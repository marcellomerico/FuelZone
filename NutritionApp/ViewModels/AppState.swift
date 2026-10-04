import Combine
import SwiftUI

enum AppTab: Hashable {
    case plan, history, snacks, settings
}

/// App-wide coordinator: owns the data store, StoreKit and the screen view models.
@MainActor
final class AppState: ObservableObject {
    // A nonisolated deinit avoids the isolated-deinit back-deployment shim, which crashes on iOS < 26
    // (swift_task_deinitOnExecutorMainActorBackDeploy) when the object is released on the main thread.
    nonisolated deinit {}

    @Published var showOnboarding: Bool
    @Published var selectedTab: AppTab = .plan
    /// Debug-only override to try Pro features without a purchase. Never synced, never in release builds.
    @Published var debugSimulatePro: Bool {
        didSet { UserDefaults.standard.set(debugSimulatePro, forKey: Self.debugProKey) }
    }

    let store: UserDataStore
    let subscriptionManager: SubscriptionManager
    let sessionViewModel: SessionViewModel
    let snackViewModel: SnackViewModel
    let onboardingViewModel: OnboardingViewModel

    private static let debugProKey = "fuelzone.debug.simulatePro"
    private var cancellables = Set<AnyCancellable>()

    /// Pro access is always derived from current StoreKit entitlements.
    var isPro: Bool {
        #if DEBUG
        subscriptionManager.isProActive || debugSimulatePro
        #else
        subscriptionManager.isProActive
        #endif
    }

    init(store: UserDataStore? = nil, subscriptionManager: SubscriptionManager? = nil) {
        #if DEBUG
        // UI tests: `-FZResetData YES` starts from a clean install.
        if store == nil, UserDefaults.standard.bool(forKey: "FZResetData") {
            FileStore.applicationSupport().removeAll()
            UserDefaults.standard.removeObject(forKey: LegacyStoreMigration.migratedFlag)
            LegacyStoreMigration.legacyKeys.values.forEach { UserDefaults.standard.removeObject(forKey: $0) }
            UserDefaults.standard.removeObject(forKey: Self.debugProKey)
        }
        let store = store ?? UserDataStore(syncService: UserDefaults.standard.bool(forKey: "FZResetData") ? nil : CloudSyncService())
        #else
        let store = store ?? UserDataStore()
        #endif
        let subscriptions = subscriptionManager ?? SubscriptionManager()
        self.store = store
        self.subscriptionManager = subscriptions
        #if DEBUG
        debugSimulatePro = UserDefaults.standard.bool(forKey: Self.debugProKey)
        #else
        debugSimulatePro = false
        #endif
        showOnboarding = !store.profile.hasCompletedOnboarding

        let onboarding = OnboardingViewModel()
        onboarding.reset(from: store.profile)
        onboardingViewModel = onboarding

        sessionViewModel = SessionViewModel(store: store)
        snackViewModel = SnackViewModel(store: store)
        let proProvider: () -> Bool = { [weak self] in self?.isPro ?? false }
        sessionViewModel.isProProvider = proProvider
        snackViewModel.isProProvider = proProvider

        L10n.updateBundle(for: store.settings.language)

        store.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        subscriptions.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        store.$settings
            .map(\.language)
            .removeDuplicates()
            .sink { L10n.updateBundle(for: $0) }
            .store(in: &cancellables)
        store.$profile
            .map(\.hasCompletedOnboarding)
            .removeDuplicates()
            .sink { [weak self] completed in
                if completed { self?.showOnboarding = false }
            }
            .store(in: &cancellables)

        Task {
            await store.syncNow()
            await subscriptions.loadProducts()
        }
    }

    /// Two-way binding to a profile field that saves immediately.
    func profileBinding<Value>(_ keyPath: WritableKeyPath<UserProfile, Value>) -> Binding<Value> {
        Binding(
            get: { self.store.profile[keyPath: keyPath] },
            set: { newValue in self.store.updateProfile { $0[keyPath: keyPath] = newValue } }
        )
    }

    /// Two-way binding to a settings field that saves immediately.
    func settingsBinding<Value: Equatable>(_ keyPath: WritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding(
            get: { self.store.settings[keyPath: keyPath] },
            set: { newValue in self.store.updateSettings { $0[keyPath: keyPath] = newValue } }
        )
    }

    func startOnboarding() {
        onboardingViewModel.reset(from: store.profile)
        showOnboarding = true
    }

    func completeOnboarding() {
        let onboarding = onboardingViewModel
        store.updateProfile { profile in
            onboarding.apply(to: &profile)
            profile.hasCompletedOnboarding = true
        }
        sessionViewModel.setup.sport = store.profile.primarySport
        showOnboarding = false
    }

    func appDidBecomeActive() {
        Task {
            await store.syncNow()
            await subscriptionManager.refreshEntitlements()
        }
    }
}
