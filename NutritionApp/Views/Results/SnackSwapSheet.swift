import SwiftUI

struct SnackSwapSheet: View {
    let snacks: [Snack]
    let onSelect: (Snack) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filtered: [Snack] {
        guard !searchText.isEmpty else { return snacks }
        return snacks.filter {
            $0.localizedName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            FuelZoneScreenScroll {
                VStack(alignment: .leading, spacing: 0) {
                    FuelZoneSectionHeader(
                        titleKey: "snack.swap.title",
                        subtitleKey: "snack.swap.subtitle",
                        systemImage: "arrow.triangle.swap"
                    )
                    .padding(.bottom, 12)

                    if filtered.isEmpty {
                        Text(localized: "snack.swap.empty")
                            .font(DesignSystem.Typography.bodySecondary)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { index, snack in
                            Button {
                                onSelect(snack)
                                dismiss()
                            } label: {
                                FuelZoneSnackRow(snack: snack)
                            }
                            .buttonStyle(.plain)
                            if index < filtered.count - 1 {
                                FuelZoneCardDivider()
                            }
                        }
                    }
                }
                .fuelZoneCard()
            }
            .searchable(text: $searchText, prompt: Text(localized: "snack.swap.search"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    FuelZoneTextButton(titleKey: "onboarding.button.back") { dismiss() }
                }
            }
        }
    }
}
