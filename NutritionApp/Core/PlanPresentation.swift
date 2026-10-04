import Foundation

/// Turns a saved plan into display models (Fuel Track stops) and share text.
enum PlanPresentation {
    static func title(for record: SessionRecord) -> String {
        if let title = record.title, !title.isEmpty { return title }
        return "\(LocalizedEnum.label(for: record.setup.sport)) · \(FZFormat.clock(minutes: record.result.sessionDurationMinutes))"
    }

    static func nutrient(for snack: Snack) -> Theme.Nutrient {
        if snack.fluidMlPerDefaultPortion != nil { return .fluids }
        return snack.carbsPerDefaultPortion > SnackComposer.carbFreeThreshold ? .carbs : .sodium
    }

    static func icon(for snack: Snack) -> String {
        if snack.fluidMlPerDefaultPortion != nil { return "waterbottle.fill" }
        return snack.category.systemImageName
    }

    /// Fuel Track rows: start, one row per stop that has something to take, finish.
    static func stops(for result: FuelingResult, snack: (SnackPortion) -> Snack?) -> [FuelTrackStop] {
        var stops = [FuelTrackStop(id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, minute: 0, kind: .start)]
        for step in result.timeline {
            var tokens: [FuelTrackToken] = step.portions.compactMap { portion in
                guard let item = snack(portion) else { return nil }
                return FuelTrackToken(
                    id: portion.id,
                    text: NutritionMetricsFormatting.portionLine(portion: portion, snack: item),
                    systemImage: icon(for: item),
                    nutrient: nutrient(for: item),
                    portionID: portion.id
                )
            }
            if step.waterMl > 0 {
                tokens.append(FuelTrackToken(
                    id: step.id,
                    text: L10n.format("results.water.step", "\(step.waterMl)"),
                    systemImage: "drop.fill",
                    nutrient: .fluids
                ))
            }
            guard !tokens.isEmpty else { continue }
            stops.append(FuelTrackStop(
                id: step.id,
                minute: intakeMinute(for: step),
                kind: .stop,
                tokens: tokens,
                isUserModified: step.isUserModified
            ))
        }
        stops.append(FuelTrackStop(
            id: UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!,
            minute: result.sessionDurationMinutes,
            kind: .finish
        ))
        return stops
    }

    /// When to take a block's fuel: three quarters into the block (0:15 for 0–20), rounded to 5 min.
    static func intakeMinute(for step: TimelineStep) -> Int {
        let offset = max(5, Int((Double(step.durationMinutes) * 0.75 / 5).rounded(.down)) * 5)
        return min(step.startMinute + offset, step.endMinute)
    }

    /// Plain-text summary for the share sheet.
    static func shareText(record: SessionRecord, summary: FuelPlanSummary, snack: (SnackPortion) -> Snack?) -> String {
        let result = record.result
        var lines: [String] = []
        lines.append("FuelZone – \(title(for: record))")
        lines.append(L10n.format(
            "share.targets",
            FZFormat.range(result.carbsPerHour),
            FZFormat.range(result.fluidsPerHourMl),
            FZFormat.range(result.sodiumPerHourMg)
        ))
        if !summary.packItems.isEmpty || summary.waterMl > 0 {
            lines.append("")
            lines.append(L10n.string("share.packList"))
            for item in summary.packItems {
                lines.append("• \(item.unitsToPack)× \(item.snack.localizedName)")
            }
            if summary.waterMl > 0 {
                lines.append("• " + L10n.format("results.water.total", "\(summary.waterMl)"))
            }
        }
        lines.append("")
        for stop in stops(for: result, snack: snack) where stop.kind == .stop {
            lines.append("\(FZFormat.clock(minutes: stop.minute))  " + stop.tokens.map(\.text).joined(separator: ", "))
        }
        return lines.joined(separator: "\n")
    }
}
