import SwiftUI

struct NutritionCardView: View {
    let titleKey: String
    let value: String
    let subtitleKey: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(localized: titleKey)
                    .font(.subheadline.weight(.semibold))
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(Color.accentColor)
            }

            Text(value)
                .font(.title2.bold())

            Text(localized: subtitleKey)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fuelZoneCard()
    }
}
