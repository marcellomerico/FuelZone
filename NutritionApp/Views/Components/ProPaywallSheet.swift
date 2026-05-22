import SwiftUI

struct ProPaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onOpenSettings: (() -> Void)?

    var body: some View {
        NavigationStack {
            FuelZoneScreenScroll {
                FuelZoneHeroBlock(
                    systemImage: "star.circle.fill",
                    titleKey: "pro.paywall.title",
                    subtitleKey: "pro.paywall.message"
                )

                VStack(alignment: .leading, spacing: 12) {
                    FuelZoneSectionHeader(
                        titleKey: "pro.paywall.featuresTitle",
                        systemImage: "checkmark.seal"
                    )
                    FuelZoneBulletRow(textKey: "pro.paywall.feature.zones", systemImage: "heart.fill")
                    FuelZoneBulletRow(textKey: "pro.paywall.feature.barcode", systemImage: "barcode.viewfinder")
                    FuelZoneBulletRow(textKey: "pro.paywall.feature.snackSwap", systemImage: "arrow.triangle.swap")
                    FuelZoneBulletRow(textKey: "pro.paywall.feature.history", systemImage: "clock.fill")
                }
                .fuelZoneCard()

                Button {
                    dismiss()
                    onOpenSettings?()
                } label: {
                    Text(localized: "pro.paywall.cta")
                }
                .buttonStyle(PrimaryButtonStyle())

                FuelZoneTextButton(titleKey: "pro.paywall.dismiss") {
                    dismiss()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
