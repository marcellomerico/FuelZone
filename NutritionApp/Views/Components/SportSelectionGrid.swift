import SwiftUI

/// Sport picker: three sports per row, stacked vertically.
struct SportSelectionGrid: View {
    @Binding var selection: SportType

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(SportType.allCases) { sport in
                Button { selection = sport } label: {
                    VStack(spacing: 8) {
                        Image(systemName: sport.systemImageName)
                            .font(.title3)
                            .foregroundStyle(selection == sport ? DesignSystem.accent : DesignSystem.textSecondary)
                        Text(localized: LocalizedEnum.key(for: sport))
                            .font(DesignSystem.Typography.caption.weight(.medium))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                            .foregroundStyle(selection == sport ? DesignSystem.accentLight : DesignSystem.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selection == sport
                            ? DesignSystem.accent.opacity(0.16)
                            : DesignSystem.inactiveSegment
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(selection == sport ? DesignSystem.accent : .clear, lineWidth: 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
