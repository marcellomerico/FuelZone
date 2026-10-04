import SwiftUI

/// Minutes per heart-rate zone; the total must match the session length.
struct ZoneEditorView: View {
    @Binding var distribution: HeartRateZoneDistribution
    let sessionMinutes: Int?
    let thresholds: HeartRateZoneThresholds?

    private var total: Int { distribution.totalMinutes }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let sessionMinutes, sessionMinutes > 0 {
                ForEach(HeartRateZone.allCases) { zone in
                    row(zone, sessionMinutes: sessionMinutes)
                }
                HStack {
                    Text(L10n.format("session.zone.total", "\(total)", "\(sessionMinutes)"))
                        .font(Theme.Typography.footnote)
                        .monospacedDigit()
                        .foregroundStyle(Theme.Colors.ink2)
                    Spacer()
                    if total != sessionMinutes {
                        Label {
                            Text(localized: "plan.zones.mismatch")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.danger)
                    }
                }
                .padding(.top, 2)
            } else {
                FZBanner(message: L10n.string("session.zone.durationRequired"))
            }

            if thresholds == nil {
                FZBanner(message: L10n.string("session.zone.setupInProfile"))
            }
        }
    }

    private func row(_ zone: HeartRateZone, sessionMinutes: Int) -> some View {
        let binding = minutesBinding(zone)
        return HStack(spacing: 10) {
            ZoneBadge(zone: zone)
            VStack(alignment: .leading, spacing: 1) {
                Text(LocalizedEnum.label(for: zone))
                    .font(Theme.Typography.subheadlineEmphasis)
                    .foregroundStyle(Theme.Colors.ink)
                if let thresholds {
                    Text(HeartRateZoneCalculator.bpmLabel(for: zone, thresholds: thresholds))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.ink2)
                }
            }
            Spacer(minLength: 4)
            Stepper(value: binding, in: 0...sessionMinutes, step: 5) {
                Text(LocalizedEnum.label(for: zone))
            }
            .labelsHidden()
            .accessibilityValue(Text(L10n.format("session.zone.minutes", "\(binding.wrappedValue)")))
            Text("\(binding.wrappedValue)′")
                .font(.headline.weight(.heavy).width(.compressed))
                .monospacedDigit()
                .foregroundStyle(Theme.Colors.ink)
                .frame(minWidth: 40, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous).fill(Theme.Colors.surface2))
    }

    private func minutesBinding(_ zone: HeartRateZone) -> Binding<Int> {
        switch zone {
        case .zone1: $distribution.zone1Minutes
        case .zone2: $distribution.zone2Minutes
        case .zone3: $distribution.zone3Minutes
        case .zone4: $distribution.zone4Minutes
        case .zone5: $distribution.zone5Minutes
        }
    }
}

/// "Z1" … "Z5" badge with rising intensity shading.
struct ZoneBadge: View {
    let zone: HeartRateZone

    var body: some View {
        Text("Z\(zone.rawValue)")
            .font(.caption.weight(.heavy).width(.expanded))
            .foregroundStyle(zone.rawValue >= 4 ? Theme.Colors.onInk : Theme.Colors.ink)
            .frame(width: 36, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(zone.rawValue >= 4 ? Theme.Colors.ink : Theme.Colors.raised)
            )
            .accessibilityHidden(true)
    }
}
