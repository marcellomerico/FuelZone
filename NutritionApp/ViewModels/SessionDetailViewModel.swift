import Combine
import Foundation

@MainActor
final class SessionDetailViewModel: ObservableObject {
    @Published private(set) var result: FuelingResult
    @Published private(set) var setup: SessionSetup
    @Published var showProPaywall = false

    private var settings: AppSettings
    private var allSnacks: [Snack] = []

    init(record: SessionRecord, settings: AppSettings, snacks: [Snack]) {
        result = record.result
        setup = record.setup
        self.settings = settings
        allSnacks = snacks
    }

    func updateSettings(_ settings: AppSettings) { self.settings = settings }

    func updateSnacks(_ snacks: [Snack]) { allSnacks = snacks }

    var canSwapSnacks: Bool { settings.hasAccess(to: .snackTimelineSwap) }

    func snack(for portion: SnackPortion) -> Snack? {
        allSnacks.first { $0.id == portion.snackID }
    }

    func swapSnack(stepID: UUID, portionID: UUID, to snack: Snack) {
        guard canSwapSnacks,
              let stepIndex = result.timeline.firstIndex(where: { $0.id == stepID }),
              let pIndex = result.timeline[stepIndex].portions.firstIndex(where: { $0.id == portionID }) else {
            if !canSwapSnacks { showProPaywall = true }
            return
        }
        result.timeline[stepIndex].portions[pIndex].snackID = snack.id
        result.timeline[stepIndex].isUserModified = true
    }

    func carbsPerHourText() -> String {
        formatRange(result.carbsPerHour, unit: L10n.string("unit.label.grams"))
    }

    func fluidsPerHourText() -> String {
        formatRange(result.fluidsPerHourMl, unit: L10n.string("unit.label.milliliters"))
    }

    func sodiumPerHourText() -> String {
        formatRange(result.sodiumPerHourMg, unit: L10n.string("unit.label.milligrams"))
    }

    func warningMessages() -> [String] {
        result.warningKeys.map { String(localized: $0) }
    }

    private func formatRange(_ range: NutritionRange, unit: String) -> String {
        if range.min == range.max {
            return "\(Int(range.min)) \(unit)"
        }
        return L10n.format("results.range.format", "\(Int(range.min))", "\(Int(range.max))", unit)
    }
}
