import Combine
import Foundation

@MainActor
final class ResultsViewModel: ObservableObject {
    @Published private(set) var result: FuelingResult?
    @Published private(set) var setup: SessionSetup?
    @Published var showSnackLibrary = false

    private var settings = AppSettings()
    private weak var snackViewModel: SnackViewModel?
    private var allSnacks: [Snack] = []

    var hasResult: Bool { result != nil }

    func configure(settings: AppSettings, snacks: SnackViewModel) {
        self.settings = settings
        snackViewModel = snacks
        allSnacks = snacks.allSnacks()
    }

    func updateSettings(_ settings: AppSettings) { self.settings = settings }

    func setResult(_ result: FuelingResult, setup: SessionSetup, profile: UserProfile) {
        self.result = result
        self.setup = setup
        allSnacks = snackViewModel?.allSnacks() ?? []
    }

    func carbsPerHourText() -> String {
        guard let result else { return "—" }
        return formatRange(result.carbsPerHour, unit: L10n.string("unit.label.grams"))
    }

    func fluidsPerHourText() -> String {
        guard let result else { return "—" }
        return formatRange(result.fluidsPerHourMl, unit: L10n.string("unit.label.milliliters"))
    }

    func sodiumPerHourText() -> String {
        guard let result else { return "—" }
        return formatRange(result.sodiumPerHourMg, unit: L10n.string("unit.label.milligrams"))
    }

    func warningMessages() -> [String] {
        result?.warningKeys.map { String(localized: $0) } ?? []
    }

    var canSwapSnacks: Bool {
        settings.hasAccess(to: .snackTimelineSwap)
    }

    func snack(for portion: SnackPortion) -> Snack? {
        allSnacks.first { $0.id == portion.snackID }
    }

    func swapSnack(stepID: UUID, portionID: UUID, to snack: Snack) {
        guard canSwapSnacks, var result,
              let stepIndex = result.timeline.firstIndex(where: { $0.id == stepID }) else {
            return
        }
        guard let pIndex = result.timeline[stepIndex].portions.firstIndex(where: { $0.id == portionID }) else {
            return
        }
        result.timeline[stepIndex].portions[pIndex].snackID = snack.id
        result.timeline[stepIndex].isUserModified = true
        self.result = result
    }

    private func formatRange(_ range: NutritionRange, unit: String) -> String {
        if range.min == range.max {
            return "\(Int(range.min)) \(unit)"
        }
        return L10n.format("results.range.format", "\(Int(range.min))", "\(Int(range.max))", unit)
    }
}
