import SwiftUI

struct IntensityModePicker: View {
    @ObservedObject var viewModel: SessionViewModel

    var body: some View {
        HStack(spacing: 0) {
            modeButton(.simple, titleKey: "session.intensity.simple", showProBadge: false)
            modeButton(.zoneBased, titleKey: "session.intensity.zoneBased", showProBadge: !viewModel.canUseZoneMode)
        }
        .padding(4)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func modeButton(_ mode: IntensityMode, titleKey: String, showProBadge: Bool) -> some View {
        let isSelected = viewModel.setup.intensityMode == mode
        return Button {
            viewModel.selectIntensityMode(mode)
        } label: {
            HStack(spacing: 4) {
                Text(localized: titleKey)
                    .font(DesignSystem.Typography.caption.weight(isSelected ? .semibold : .regular))
                if showProBadge {
                    Text(localized: "session.intensity.proBadge")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(DesignSystem.accentSoft)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? DesignSystem.cardBackground : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: isSelected ? .black.opacity(0.06) : .clear, radius: 4, y: 1)
        }
        .buttonStyle(.plain)
    }
}
