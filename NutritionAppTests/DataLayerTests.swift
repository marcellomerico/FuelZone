import XCTest
@testable import NutritionApp

@MainActor
final class DataLayerTests: XCTestCase {

    private func sampleResult(minutes: Int = 60, snacks: [Snack] = []) throws -> FuelingResult {
        try FuelingCalculator.calculate(
            FuelingCalculatorInput(
                profile: UserProfile(),
                setup: SessionSetup(durationMinutes: minutes),
                availableSnacks: snacks
            )
        )
    }

    // MARK: - Snack kit

    func testNewUser_getsStarterKit() {
        let store = TestStores.make()
        let names = Set(store.kitSnacks.compactMap(\.nameKey))
        XCTAssertEqual(names, Set(SnackLibrary.starterKitNameKeys))
    }

    func testLegacyLibrary_keepsPreviouslyEnabledBuiltIns() throws {
        let builtIns = try DefaultSnackLoader.loadBuiltInSnacks()
        let disabled = builtIns[0].id
        let legacy = """
        {"builtInSnackIDs":[],"customSnacks":[],"disabledBuiltInIDs":["\(disabled.uuidString)"]}
        """
        let defaults = TestStores.freshDefaults()
        defaults.set(Data(legacy.utf8), forKey: "fuelzone.snackLibraryState")

        let store = TestStores.make(defaults: defaults)
        XCTAssertFalse(store.isInKit(disabled))
        XCTAssertEqual(store.kitSnacks.count, builtIns.count - 1)
    }

    func testKitToggle_keepsSnackInCatalog() throws {
        let store = TestStores.make()
        let snack = try XCTUnwrap(store.kitSnacks.first)
        store.setInKit(snack.id, false)
        XCTAssertFalse(store.isInKit(snack.id))
        XCTAssertTrue(store.allSnacks.contains { $0.id == snack.id })
    }

    func testPlannerOnlyUsesKitSnacks() throws {
        let store = TestStores.make()
        let vm = SessionViewModel(store: store)
        vm.setup = SessionSetup(durationMinutes: 150, simpleIntensity: .hard)
        let result = try XCTUnwrap(vm.calculatePlan())
        let kitIDs = Set(store.kitSnacks.map(\.id))
        let used = Set(result.timeline.flatMap(\.portions).map(\.snackID))
        XCTAssertFalse(used.isEmpty)
        XCTAssertTrue(used.isSubset(of: kitIDs))
    }

    // MARK: - History & Pro

    func testHistory_isNeverTruncated_freeTierOnlyLimitsVisibility() throws {
        let store = TestStores.make()
        let result = try sampleResult()
        for _ in 0..<15 { store.addSession(setup: SessionSetup(), result: result) }
        XCTAssertEqual(store.history.count, 15)
        XCTAssertEqual(store.visibleHistory(isPro: false).count, AppConstants.freeHistorySessionLimit)
        XCTAssertEqual(store.visibleHistory(isPro: true).count, 15)
    }

    func testDeleteSession_createsTombstone() throws {
        let store = TestStores.make()
        let record = store.addSession(setup: SessionSetup(), result: try sampleResult())
        store.deleteSession(id: record.id)
        XCTAssertNil(store.session(id: record.id))
        let tombstone = store.localEnvelopes().first { $0.key == UserDataStore.sessionKey(record.id) }
        XCTAssertEqual(tombstone?.isDeleted, true)
    }

    func testLegacySettings_ignoreStoredProFlag() throws {
        let legacy = #"{"appearance":"dark","language":"de","isProSubscriber":true}"#
        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(legacy.utf8))
        XCTAssertEqual(settings.appearance, .dark)
        XCTAssertEqual(settings.language, .german)
        let encoded = String(decoding: try JSONEncoder().encode(settings), as: UTF8.self)
        XCTAssertFalse(encoded.contains("isProSubscriber"))
    }

    func testAppState_proIsDerivedFromEntitlements() {
        let appState = AppState(store: TestStores.make())
        appState.debugSimulatePro = false
        XCTAssertFalse(appState.isPro)
        XCTAssertFalse(appState.sessionViewModel.canUseZoneMode)
        appState.debugSimulatePro = true
        XCTAssertTrue(appState.isPro)
        XCTAssertTrue(appState.sessionViewModel.canUseZoneMode)
        appState.debugSimulatePro = false
    }

    // MARK: - Persistence

    func testDataSurvivesRestart() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let defaults = TestStores.freshDefaults()
        let first = UserDataStore(files: FileStore(directory: directory), syncService: nil, defaults: defaults)
        first.updateProfile { $0.displayName = "Alex"; $0.weightKg = 68 }
        first.addSession(setup: SessionSetup(), result: try sampleResult())

        let second = UserDataStore(files: FileStore(directory: directory), syncService: nil, defaults: defaults)
        XCTAssertEqual(second.profile.displayName, "Alex")
        XCTAssertEqual(second.history.count, 1)
    }

    func testLegacyUserDefaultsMigration() throws {
        let defaults = TestStores.freshDefaults()
        let profile = UserProfile(displayName: "Legacy", hasCompletedOnboarding: true)
        defaults.set(try JSONEncoder().encode(profile), forKey: "fuelzone.userProfile")
        let store = TestStores.make(defaults: defaults)
        XCTAssertEqual(store.profile.displayName, "Legacy")
        XCTAssertTrue(store.profile.hasCompletedOnboarding)
    }

    func testFreshProfile_neverOverridesCloudProfile() {
        let store = TestStores.make()
        XCTAssertEqual(store.profile.updatedAt, .distantPast)
        let remote = SyncEnvelope(key: "profile", modifiedAt: .now, payload: Data("{}".utf8))
        let outcome = SyncMerge.merge(local: store.localEnvelopes(), remote: [remote])
        XCTAssertTrue(outcome.toApplyLocally.contains { $0.key == "profile" })
        XCTAssertFalse(outcome.toUpload.contains { $0.key == "profile" })
    }

    // MARK: - Sync merge

    func testSyncMerge_newestWins() {
        let old = Date(timeIntervalSince1970: 100)
        let new = Date(timeIntervalSince1970: 200)
        let local = [
            SyncEnvelope(key: "a", modifiedAt: new, payload: Data("L".utf8)),
            SyncEnvelope(key: "b", modifiedAt: old, payload: Data("L".utf8)),
            SyncEnvelope(key: "c", modifiedAt: old, payload: Data("L".utf8)),
        ]
        let remote = [
            SyncEnvelope(key: "a", modifiedAt: old, payload: Data("R".utf8)),
            SyncEnvelope(key: "b", modifiedAt: new, payload: Data("R".utf8)),
            SyncEnvelope(key: "d", modifiedAt: old, payload: Data("R".utf8)),
        ]
        let outcome = SyncMerge.merge(local: local, remote: remote)
        XCTAssertEqual(outcome.toUpload.map(\.key), ["a", "c"])
        XCTAssertEqual(outcome.toApplyLocally.map(\.key), ["b", "d"])
    }

    func testSyncMerge_equalTimestampsDoNothing() {
        let date = Date(timeIntervalSince1970: 100)
        let item = SyncEnvelope(key: "a", modifiedAt: date, payload: Data("x".utf8))
        let outcome = SyncMerge.merge(local: [item], remote: [item])
        XCTAssertTrue(outcome.toUpload.isEmpty)
        XCTAssertTrue(outcome.toApplyLocally.isEmpty)
    }

    func testApplyRemote_tombstoneRemovesSession_newerRecordRestoresIt() throws {
        let store = TestStores.make()
        let record = store.addSession(setup: SessionSetup(), result: try sampleResult())
        let key = UserDataStore.sessionKey(record.id)

        store.apply([SyncEnvelope(key: key, modifiedAt: .now, payload: nil)])
        XCTAssertNil(store.session(id: record.id))

        var revived = record
        revived.modifiedAt = .now.addingTimeInterval(10)
        store.apply([SyncEnvelope(key: key, modifiedAt: revived.modifiedAt, payload: try JSONEncoder.fuelZone.encode(revived))])
        XCTAssertNotNil(store.session(id: record.id))
    }

    func testApplyRemote_ignoresOlderCopyThanLocalEdit() throws {
        let store = TestStores.make()
        var older = store.profile
        older.displayName = "Remote"
        older.updatedAt = Date(timeIntervalSinceNow: -60)
        store.updateProfile { $0.displayName = "Local" }   // edited while a sync was in flight
        store.apply([SyncEnvelope(key: "profile", modifiedAt: older.updatedAt, payload: try JSONEncoder.fuelZone.encode(older))])
        XCTAssertEqual(store.profile.displayName, "Local")
    }

    // MARK: - Plan editing

    func testSwap_persistsToHistory_andKeepsCarbsSimilar() throws {
        let store = TestStores.make()
        let snacks = try DefaultSnackLoader.loadBuiltInSnacks()
        let gel40 = try XCTUnwrap(snacks.first { $0.nameKey == "snack.gel.maurten160" })
        let gel25 = try XCTUnwrap(snacks.first { $0.nameKey == "snack.gel.maurten100" })
        let result = try sampleResult(minutes: 120, snacks: [gel40])
        let record = store.addSession(setup: SessionSetup(durationMinutes: 120), result: result)
        let step = try XCTUnwrap(result.timeline.first { !$0.portions.isEmpty })
        let portion = try XCTUnwrap(step.portions.first)

        let vm = PlanResultViewModel(recordID: record.id, store: store, isPro: { true })
        vm.swap(stepID: step.id, portionID: portion.id, to: gel25)

        let saved = try XCTUnwrap(store.session(id: record.id))
        let swapped = try XCTUnwrap(saved.result.timeline.first { $0.id == step.id }?.portions.first { $0.id == portion.id })
        XCTAssertEqual(swapped.snackID, gel25.id)
        XCTAssertEqual(gel25.carbs(forQuantity: swapped.quantity), gel40.carbs(forQuantity: portion.quantity), accuracy: 13)
        XCTAssertTrue(saved.result.usedSnacks.contains { $0.id == gel25.id })
    }

    func testSwap_requiresPro() throws {
        let store = TestStores.make()
        let result = try sampleResult(minutes: 120, snacks: store.kitSnacks)
        let record = store.addSession(setup: SessionSetup(durationMinutes: 120), result: result)
        let step = try XCTUnwrap(result.timeline.first { !$0.portions.isEmpty })
        let vm = PlanResultViewModel(recordID: record.id, store: store, isPro: { false })
        vm.swap(stepID: step.id, portionID: step.portions[0].id, to: store.allSnacks[0])
        XCTAssertTrue(vm.showProPaywall)
        XCTAssertEqual(store.session(id: record.id)?.result, result)
    }

    func testPlanResult_showsSnacksForHistoryEntries() throws {
        let store = TestStores.make()
        let result = try sampleResult(minutes: 120, snacks: store.kitSnacks)
        let record = store.addSession(setup: SessionSetup(durationMinutes: 120), result: result)
        let vm = PlanResultViewModel(recordID: record.id, store: store, isPro: { false })
        let portions = result.timeline.flatMap(\.portions)
        XCTAssertFalse(portions.isEmpty)
        XCTAssertTrue(portions.allSatisfy { vm.snack(for: $0) != nil })
    }

    // MARK: - Onboarding

    func testOnboardingRestart_beginsAtFirstStep_andKeepsProfileIdentity() {
        let vm = OnboardingViewModel()
        vm.stepIndex = 3
        var profile = UserProfile(maxHeartRate: 190)
        profile.zoneThresholds = HeartRateZoneThresholds(maxHeartRate: 190, zone1Upper: 120, zone2Upper: 140, zone3Upper: 160, zone4Upper: 175)
        let originalID = profile.id
        vm.reset(from: profile)
        XCTAssertEqual(vm.stepIndex, 0)
        vm.sweatRate = .high
        vm.apply(to: &profile)
        XCTAssertEqual(profile.id, originalID)
        XCTAssertEqual(profile.zoneThresholds?.zone1Upper, 120, "Custom zones must survive repeating the onboarding")
        XCTAssertEqual(profile.sweatRate, .high)
    }

    // MARK: - Barcode

    func testBarcode_duplicateScanReturnsExistingSnack() async {
        let store = TestStores.make()
        let existing = Snack(nameEN: "Bar", category: .solid, carbsPerServing: 60, sodiumMgPerServing: 100, unitKey: "unit.bar", barcode: "4000000000000")
        store.addCustomSnack(existing)
        let vm = SnackViewModel(store: store)
        vm.isProProvider = { true }
        let outcome = await vm.handleScannedBarcode("4000000000000")
        XCTAssertEqual(outcome, .alreadyInLibrary(existing.withKitDefaults))
        XCTAssertEqual(store.library.customSnacks.count, 1)
    }
}

private extension Snack {
    /// `addCustomSnack` normalizes these flags.
    var withKitDefaults: Snack {
        var copy = self
        copy.isBuiltIn = false
        copy.isEnabled = true
        return copy
    }
}
