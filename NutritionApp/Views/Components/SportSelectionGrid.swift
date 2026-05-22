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
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(SportType.allCases) { sport in
                Button { selection = sport } label: {
                    VStack(spacing: 8) {
                        Image(systemName: sport.systemImageName)
                            .font(.title3)
                            .foregroundStyle(selection == sport ? Color.accentColor : .secondary)
                        Text(LocalizedEnum.label(for: sport))
                            .font(DesignSystem.Typography.caption.weight(.medium))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selection == sport ? DesignSystem.accentSoft : Color(.tertiarySystemGroupedBackground))
                    .foregroundStyle(selection == sport ? Color.accentColor : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
