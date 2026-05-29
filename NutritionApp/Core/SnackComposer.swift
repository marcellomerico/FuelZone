import Foundation

/// Greedy snack assignment per timeline step to approximate carb, sodium, and fluid targets.
enum SnackComposer {
    private static let maxPortionsPerStep = 8
    private static let carbTolerance = 0.85
    private static let sodiumTolerance = 0.80

    private static let fluidMlByUnitKey: [String: Int] = [
        "unit.ml500": 500,
        "unit.ml330": 330,
        "unit.ml250": 250,
    ]

    static func compose(
        steps: inout [TimelineStep],
        availableSnacks: [Snack]
    ) {
        let snacks = availableSnacks.filter(\.isEnabled)
        guard !snacks.isEmpty else { return }

        for index in steps.indices {
            steps[index].portions = greedyPortions(
                targetCarbs: steps[index].targetCarbsGrams,
                targetSodium: steps[index].targetSodiumMg,
                targetFluids: steps[index].targetFluidsMl,
                snacks: snacks
            )
        }
    }

    private static func greedyPortions(
        targetCarbs: Double,
        targetSodium: Double,
        targetFluids: Int,
        snacks: [Snack]
    ) -> [SnackPortion] {
        var portions: [SnackPortion] = []
        var carbs = 0.0
        var sodium = 0.0
        var fluids = 0

        func snack(for id: UUID) -> Snack? {
            snacks.first { $0.id == id }
        }

        func add(_ snack: Snack, quantity: Double = 1) {
            portions.append(SnackPortion(snackID: snack.id, quantity: quantity))
            carbs += snack.carbs(forQuantity: quantity)
            sodium += snack.sodiumMg(forQuantity: quantity)
            fluids += fluidMl(for: snack) * Int(quantity.rounded())
        }

        var iteration = 0
        while iteration < maxPortionsPerStep {
            iteration += 1
            let needCarbs = carbs < targetCarbs * carbTolerance
            let needSodium = sodium < targetSodium * sodiumTolerance
            let needFluids = fluids < targetFluids / 2

            if !needCarbs, !needSodium, !needFluids { break }

            if needCarbs, let snack = bestCarbSnack(snacks: snacks, portions: portions) {
                add(snack)
                continue
            }

            if needSodium, let snack = bestSodiumSnack(snacks: snacks, portions: portions) {
                add(snack)
                continue
            }

            if needFluids, let snack = bestDrinkSnack(snacks: snacks, portions: portions) {
                add(snack)
                continue
            }

            break
        }

        return portions
    }

    private static func bestCarbSnack(snacks: [Snack], portions: [SnackPortion]) -> Snack? {
        snacks
            .filter { $0.carbsPerDefaultPortion > 0 }
            .sorted { $0.carbsPerDefaultPortion > $1.carbsPerDefaultPortion }
            .first { snack in
                !portions.contains { $0.snackID == snack.id && $0.quantity >= 2 }
            }
    }

    private static func bestSodiumSnack(snacks: [Snack], portions: [SnackPortion]) -> Snack? {
        snacks
            .filter { $0.sodiumMgPerDefaultPortion > 0 }
            .sorted { $0.sodiumMgPerDefaultPortion > $1.sodiumMgPerDefaultPortion }
            .first { snack in
                portions.filter { $0.snackID == snack.id }.count < 2
            }
    }

    private static func bestDrinkSnack(snacks: [Snack], portions: [SnackPortion]) -> Snack? {
        snacks
            .filter { $0.category == .drink && fluidMl(for: $0) > 0 }
            .first { snack in
                !portions.contains { $0.snackID == snack.id }
            }
    }

    private static func fluidMl(for snack: Snack) -> Int {
        fluidMlByUnitKey[snack.unitKey] ?? 0
    }
}
