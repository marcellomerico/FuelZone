import SwiftUI

#if DEBUG
/// Living style guide for the design system (Xcode previews only).
struct DesignSystemPreview: View {
    @State private var segment = 0
    @State private var chip = 0
    @State private var text = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                FZScreenHeader(eyebrow: "Design-System", title: "Race Instrument")
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    MetricText("1:30", size: 92)
                    Text("Std.").font(Theme.Typography.bodyEmphasis).foregroundStyle(Theme.Colors.ink2)
                }
                HStack {
                    FZChip(title: "Laufen", systemImage: "figure.run", isSelected: chip == 0) { chip = 0 }
                    FZChip(title: "Rad", systemImage: "bicycle", isSelected: chip == 1) { chip = 1 }
                }
                FZSegmentedControl(
                    options: [.init(value: 0, title: "Einfach"), .init(value: 1, title: "Zonen", badge: "PRO")],
                    selection: $segment
                )
                HStack {
                    FZDataToken(text: "1 Gel", systemImage: "bolt.fill", nutrient: .carbs)
                    FZDataToken(text: "150 ml Iso", systemImage: "waterbottle.fill", nutrient: .fluids)
                    FZDataToken(text: "1 Salz", systemImage: "diamond.fill", nutrient: .sodium)
                }
                CarbTierMeter(target: NutritionRange(min: 47, max: 55), planned: 50).fzCard()
                FZTextField(label: "Gewicht", text: $text, placeholder: "z. B. 70", unit: "kg", keyboard: .decimalPad)
                FZBanner(message: "Snacks im Kit werden für deine Pläne genutzt.")
                Button("Plan erstellen") {}.buttonStyle(.fzPrimary)
                Button("Teilen") {}.buttonStyle(.fzSecondary)
                FuelTrackView(
                    stops: [
                        FuelTrackStop(id: UUID(), minute: 0, kind: .start),
                        FuelTrackStop(id: UUID(), minute: 20, kind: .stop, tokens: [
                            FuelTrackToken(id: UUID(), text: "1 Gel", systemImage: "bolt.fill", nutrient: .carbs, portionID: UUID()),
                            FuelTrackToken(id: UUID(), text: "150 ml Iso", systemImage: "waterbottle.fill", nutrient: .fluids, portionID: UUID()),
                        ]),
                        FuelTrackStop(id: UUID(), minute: 40, kind: .stop, tokens: [
                            FuelTrackToken(id: UUID(), text: "200 ml Wasser", systemImage: "drop.fill", nutrient: .fluids),
                        ]),
                        FuelTrackStop(id: UUID(), minute: 60, kind: .finish),
                    ],
                    canSwap: true,
                    onSwap: { _, _ in }
                )
            }
            .padding(Theme.Spacing.screen)
        }
        .fzScreenBackground()
    }
}

#Preview("Light") { DesignSystemPreview().preferredColorScheme(.light) }
#Preview("Dark") { DesignSystemPreview().preferredColorScheme(.dark) }
#endif
