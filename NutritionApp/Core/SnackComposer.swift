import Foundation

/// Assigns snacks to timeline stops so the plan tracks the carbohydrate, sodium and fluid targets.
///
/// The composer balances **cumulative** targets instead of filling every stop on its own: a 40 g gel
/// is placed every second stop rather than overshooting a 17 g stop. Each pick is bounded so the plan
/// never runs far ahead of the target.
enum SnackComposer {
    /// At most this many carbohydrate items (gels, solids) per stop.
    static let maxCarbItemsPerStop = 2
    /// An item may be at most this multiple of the running deficit (bounds the overshoot).
    static let carbOvershootTolerance = 1.15
    /// The last stop may overshoot a little more, so the session does not end with a large gap.
    static let lastStopOvershootTolerance = 1.5
    static let sodiumOvershootTolerance = 1.05
    /// Share of a stop's carb target that may come from a carbohydrate drink; the rest comes from gels/solids.
    static let drinkCarbShare = 0.8
    /// Fluid amounts are rounded to sip-friendly steps.
    static let fluidStepMl = 50.0
    /// Carbohydrates at or below this count as “no carbs” (electrolyte products).
    static let carbFreeThreshold = 5.0

    static func compose(steps: inout [TimelineStep], availableSnacks: [Snack]) {
        let snacks = availableSnacks.filter(\.isEnabled)
        let drink = preferredDrink(in: snacks)
        // Gels can be taken in halves, which matters for short sessions with small targets.
        let carbItems: [Candidate] = snacks
            .filter { $0.fluidMlPerDefaultPortion == nil && $0.carbsPerDefaultPortion > carbFreeThreshold }
            .flatMap { snack -> [Candidate] in
                let whole = Candidate(snack: snack, quantity: 1)
                return snack.category == .gel ? [whole, Candidate(snack: snack, quantity: 0.5)] : [whole]
            }
        let saltItems: [Candidate] = snacks
            .filter {
                $0.fluidMlPerDefaultPortion == nil
                    && $0.carbsPerDefaultPortion <= carbFreeThreshold
                    && $0.sodiumMgPerDefaultPortion > 0
            }
            .map { Candidate(snack: $0, quantity: 1) }

        var targetCarbs = 0.0
        var plannedCarbs = 0.0
        var targetSodium = 0.0
        var plannedSodium = 0.0
        var uses: [UUID: Int] = [:]

        for index in steps.indices {
            let isLastStop = index == steps.index(before: steps.endIndex)
            var portions: [SnackPortion] = []
            targetCarbs += steps[index].targetCarbsGrams
            targetSodium += steps[index].targetSodiumMg

            // 1. Fluids: sip the carbohydrate drink (bounded by its carb share), top up with water.
            var fluidLeft = Double(steps[index].targetFluidsMl)
            if let drink, let bottleMl = drink.fluidMlPerDefaultPortion {
                let carbsPerMl = drink.carbs(forQuantity: 1) / bottleMl
                let carbCapMl = carbsPerMl > 0
                    ? steps[index].targetCarbsGrams * drinkCarbShare / carbsPerMl
                    : fluidLeft
                let drinkMl = roundDown(min(fluidLeft, carbCapMl), to: fluidStepMl)
                if drinkMl >= fluidStepMl {
                    let quantity = drinkMl / bottleMl
                    portions.append(SnackPortion(snackID: drink.id, quantity: quantity))
                    plannedCarbs += drink.carbs(forQuantity: quantity)
                    plannedSodium += drink.sodiumMg(forQuantity: quantity)
                    uses[drink.id, default: 0] += 1
                    fluidLeft -= drinkMl
                }
            }
            steps[index].waterMl = Int(roundToNearest(max(0, fluidLeft), step: fluidStepMl))

            // 2. Carbohydrates: close the running deficit with the best-fitting item.
            let tolerance = isLastStop ? lastStopOvershootTolerance : carbOvershootTolerance
            for _ in 0..<maxCarbItemsPerStop {
                let deficit = targetCarbs - plannedCarbs
                let sodiumHeadroom = targetSodium - plannedSodium
                guard let item = bestFit(
                    deficit: deficit,
                    candidates: carbItems,
                    amount: { $0.carbs },
                    tolerance: tolerance,
                    uses: uses,
                    // Prefer low-sodium gels once the sodium target is already covered (25 mg ≈ 1 g of carb error).
                    penalty: { max(0, $0.sodium - sodiumHeadroom) / 25 }
                ) else { break }
                portions.append(SnackPortion(snackID: item.snack.id, quantity: item.quantity))
                plannedCarbs += item.carbs
                plannedSodium += item.sodium
                uses[item.snack.id, default: 0] += 1
            }

            // 3. Sodium: add an electrolyte item when the running deficit justifies one.
            let sodiumDeficit = targetSodium - plannedSodium
            if let salt = bestFit(
                deficit: sodiumDeficit,
                candidates: saltItems,
                amount: { $0.sodium },
                tolerance: sodiumOvershootTolerance,
                uses: uses
            ) {
                portions.append(SnackPortion(snackID: salt.snack.id, quantity: salt.quantity))
                plannedSodium += salt.sodium
                uses[salt.snack.id, default: 0] += 1
            }

            steps[index].portions = portions
        }
    }

    /// Prefers an isotonic-style drink (≈ 6 g carbs per 100 ml) over sodas or plain electrolyte water.
    static func preferredDrink(in snacks: [Snack]) -> Snack? {
        snacks
            .filter { $0.fluidMlPerDefaultPortion != nil }
            .min { lhs, rhs in
                drinkScore(lhs) < drinkScore(rhs)
            }
    }

    private static func drinkScore(_ drink: Snack) -> Double {
        guard let ml = drink.fluidMlPerDefaultPortion, ml > 0 else { return .infinity }
        let carbsPer100ml = drink.carbs(forQuantity: 1) / ml * 100
        return abs(carbsPer100ml - 6)
    }

    /// Picks the candidate whose amount is closest to the deficit without exceeding
    /// `deficit × tolerance`. Ties go to the less used snack, then to a stable order.
    private static func bestFit(
        deficit: Double,
        candidates: [Candidate],
        amount: (Candidate) -> Double,
        tolerance: Double,
        uses: [UUID: Int],
        penalty: (Candidate) -> Double = { _ in 0 }
    ) -> Candidate? {
        guard deficit > 0 else { return nil }
        return candidates
            .filter { snack in
                let value = amount(snack)
                return value > 0 && value <= deficit * tolerance
            }
            .min { lhs, rhs in
                let lhsError = abs(deficit - amount(lhs)) + penalty(lhs)
                let rhsError = abs(deficit - amount(rhs)) + penalty(rhs)
                if abs(lhsError - rhsError) > 0.5 { return lhsError < rhsError }
                if lhs.quantity != rhs.quantity { return lhs.quantity > rhs.quantity }
                let lhsUses = uses[lhs.snack.id, default: 0]
                let rhsUses = uses[rhs.snack.id, default: 0]
                if lhsUses != rhsUses { return lhsUses < rhsUses }
                return lhs.snack.id.uuidString < rhs.snack.id.uuidString
            }
    }

    /// A snack in a specific amount (whole or half portion).
    private struct Candidate {
        let snack: Snack
        let quantity: Double
        var carbs: Double { snack.carbs(forQuantity: quantity) }
        var sodium: Double { snack.sodiumMg(forQuantity: quantity) }
    }

    private static func roundDown(_ value: Double, to step: Double) -> Double {
        (value / step).rounded(.down) * step
    }

    private static func roundToNearest(_ value: Double, step: Double) -> Double {
        (value / step).rounded() * step
    }
}
