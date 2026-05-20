import SwiftUI

struct FuelTimelineView: View {
    @ObservedObject var viewModel: ResultsViewModel
    let snacks: [Snack]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localized: "results.timeline")
                .font(.headline)

            if let timeline = viewModel.result?.timeline {
                ForEach(timeline) { step in
                    TimelineStepRow(step: step, viewModel: viewModel, snacks: snacks)
                }
            }
        }
    }
}

private struct TimelineStepRow: View {
    let step: TimelineStep
    @ObservedObject var viewModel: ResultsViewModel
    let snacks: [Snack]

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack {
                Circle().fill(Color.accentColor).frame(width: 10, height: 10)
                Rectangle().fill(Color.accentColor.opacity(0.3)).frame(width: 2)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.format("timeline.step.range", "\(step.startMinute)", "\(step.endMinute)"))
                    .font(.subheadline.weight(.semibold))

                Text("\(Int(step.targetCarbsGrams)) g · \(step.targetFluidsMl) ml · \(Int(step.targetSodiumMg)) mg")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(step.portions) { portion in
                    if let snack = viewModel.snack(for: portion) {
                        HStack {
                            Image(systemName: snack.category.systemImageName)
                            Text("\(portion.quantity, specifier: "%.1f")× \(snack.localizedName)")
                                .font(.caption)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fuelZoneCard()
        }
    }
}
