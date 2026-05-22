import SwiftUI

struct NutritionCardView: View {
    let titleKey: String
    let value: String
    let subtitleKey: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 44, height: 44)
                .background(DesignSystem.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(localized: titleKey)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(DesignSystem.Typography.metricValue)
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                Text(localized: subtitleKey)
                    .font(DesignSystem.Typography.metricUnit)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .fuelZoneCard()
    }
}
