import SwiftUI

struct ZoneEditorView: View {
    @Binding var distribution: HeartRateZoneDistribution
    let sessionDurationMinutes: Int?
    let thresholds: HeartRateZoneThresholds?
    private var sessionMinutes: Int { max(sessionDurationMinutes ?? 0, 0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(localized: "session.zone.title")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.textSecondary)

            if sessionDurationMinutes == nil {
                FuelZoneInfoBanner(
                    message: String(localized: "session.zone.durationRequired"),
                    style: .info
                )
            }

            if thresholds == nil {
                FuelZoneInfoBanner(
                    message: String(localized: "session.zone.setupInProfile"),
                    style: .info
                )
            }

            if sessionMinutes > 0 {
                if let thresholds {
                    zoneStepper(titleKey: "hrzone.zone1", bpm: HeartRateZoneCalculator.bpmLabel(for: .zone1, thresholds: thresholds), value: $distribution.zone1Minutes)
                    zoneStepper(titleKey: "hrzone.zone2", bpm: HeartRateZoneCalculator.bpmLabel(for: .zone2, thresholds: thresholds), value: $distribution.zone2Minutes)
                    zoneStepper(titleKey: "hrzone.zone3", bpm: HeartRateZoneCalculator.bpmLabel(for: .zone3, thresholds: thresholds), value: $distribution.zone3Minutes)
                    zoneStepper(titleKey: "hrzone.zone4", bpm: HeartRateZoneCalculator.bpmLabel(for: .zone4, thresholds: thresholds), value: $distribution.zone4Minutes)
                    zoneStepper(titleKey: "hrzone.zone5", bpm: HeartRateZoneCalculator.bpmLabel(for: .zone5, thresholds: thresholds), value: $distribution.zone5Minutes)
                } else {
                    zoneStepper(titleKey: "hrzone.zone1", bpm: nil, value: $distribution.zone1Minutes)
                    zoneStepper(titleKey: "hrzone.zone2", bpm: nil, value: $distribution.zone2Minutes)
                    zoneStepper(titleKey: "hrzone.zone3", bpm: nil, value: $distribution.zone3Minutes)
                    zoneStepper(titleKey: "hrzone.zone4", bpm: nil, value: $distribution.zone4Minutes)
                    zoneStepper(titleKey: "hrzone.zone5", bpm: nil, value: $distribution.zone5Minutes)
                }

                HStack {
                    Text(L10n.format("session.zone.total", "\(distribution.totalMinutes)", "\(sessionMinutes)"))
                        .font(DesignSystem.Typography.caption)
                    Spacer()
                    if distribution.totalMinutes != sessionMinutes {
                        Text(localized: "session.zone.validation")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    private func zoneStepper(titleKey: String, bpm: String?, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localized: titleKey)
                        .font(DesignSystem.Typography.cardTitle)
                    if let bpm {
                        Text(bpm)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.textSecondary)
                    }
                }
                Spacer()
                Stepper(
                    L10n.format("session.zone.minutes", "\(value.wrappedValue)"),
                    value: value,
                    in: 0...sessionMinutes,
                    step: 1
                )
                .labelsHidden()
                Text(L10n.format("session.zone.minutes", "\(value.wrappedValue)"))
                    .monospacedDigit()
                    .font(DesignSystem.Typography.bodySecondary.weight(.semibold))
                    .frame(minWidth: 56, alignment: .trailing)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(DesignSystem.embeddedTrack)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}
