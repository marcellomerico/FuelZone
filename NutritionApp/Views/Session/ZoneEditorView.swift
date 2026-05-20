import SwiftUI

struct ZoneEditorView: View {
    @Binding var distribution: HeartRateZoneDistribution
    @Binding var maxHeartRateText: String
    let onMaxHRChange: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(String(localized: "session.zone.maxHR"), text: $maxHeartRateText)
                .onChange(of: maxHeartRateText) { _, value in onMaxHRChange(value) }
            .keyboardType(.numberPad)
            .textFieldStyle(.roundedBorder)

            zoneSlider(titleKey: "hrzone.zone1", value: $distribution.zone1Percent)
            zoneSlider(titleKey: "hrzone.zone2", value: $distribution.zone2Percent)
            zoneSlider(titleKey: "hrzone.zone3", value: $distribution.zone3Percent)
            zoneSlider(titleKey: "hrzone.zone4", value: $distribution.zone4Percent)
            zoneSlider(titleKey: "hrzone.zone5", value: $distribution.zone5Percent)

            HStack {
                Text("Total: \(Int(distribution.totalPercent))%")
                    .font(.caption)
                Spacer()
                if !distribution.isValid {
                    Text(localized: "session.zone.validation")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .fuelZoneCard()
    }

    private func zoneSlider(titleKey: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(localized: titleKey)
                Spacer()
                Text("\(Int(value.wrappedValue))%")
                    .monospacedDigit()
            }
            .font(.caption)
            Slider(value: value, in: 0...100, step: 5)
        }
    }
}
