import SwiftUI

struct FuelingMethodologyView: View {
    var body: some View {
        FuelZoneScreenScroll {
            heroSection
            whySection
            howSection
            tiersSection
            adjustmentsSection
            fluidsSection
            referencesSection
            disclaimerSection
        }
        .navigationTitle(Text(localized: "methodology.title"))
        .navigationBarTitleDisplayMode(.large)
    }

    private var heroSection: some View {
        FuelZoneHeroBlock(
            systemImage: "book.closed.fill",
            subtitleKey: "methodology.hero.subtitle"
        )
    }

    private var whySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FuelZoneSectionHeader(
                titleKey: "methodology.why.title",
                systemImage: "questionmark.circle"
            )
            Text(localized: "methodology.why.body")
                .font(DesignSystem.Typography.bodySecondary)
                .foregroundStyle(DesignSystem.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .fuelZoneCard()
    }

    private var howSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            FuelZoneSectionHeader(
                titleKey: "methodology.how.title",
                subtitleKey: "methodology.how.subtitle",
                systemImage: "list.number"
            )
            FuelZoneNumberedStep(number: 1, titleKey: "methodology.step1.title", bodyKey: "methodology.step1.body")
            FuelZoneNumberedStep(number: 2, titleKey: "methodology.step2.title", bodyKey: "methodology.step2.body")
            FuelZoneNumberedStep(number: 3, titleKey: "methodology.step3.title", bodyKey: "methodology.step3.body")
            FuelZoneNumberedStep(number: 4, titleKey: "methodology.step4.title", bodyKey: "methodology.step4.body")
        }
        .fuelZoneCard()
    }

    private var tiersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FuelZoneSectionHeader(
                titleKey: "methodology.tiers.title",
                subtitleKey: "methodology.tiers.subtitle",
                systemImage: "clock"
            )
            FuelZoneDurationTierCard(
                durationKey: "methodology.tier.short.duration",
                amountKey: "methodology.tier.short.amount",
                tipKey: "methodology.tier.short.tip",
                icon: "hare"
            )
            FuelZoneDurationTierCard(
                durationKey: "methodology.tier.medium.duration",
                amountKey: "methodology.tier.medium.amount",
                tipKey: "methodology.tier.medium.tip",
                icon: "figure.run"
            )
            FuelZoneDurationTierCard(
                durationKey: "methodology.tier.long.duration",
                amountKey: "methodology.tier.long.amount",
                tipKey: "methodology.tier.long.tip",
                icon: "mountain.2"
            )
        }
    }

    private var adjustmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FuelZoneSectionHeader(
                titleKey: "methodology.adjustments.title",
                systemImage: "slider.horizontal.3"
            )
            FuelZoneBulletRow(textKey: "methodology.adjustment.intensity.body", systemImage: "heart.fill")
            FuelZoneBulletRow(textKey: "methodology.adjustment.stomach.body", systemImage: "leaf.fill")
        }
        .fuelZoneCard()
    }

    private var fluidsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            FuelZoneSectionHeader(
                titleKey: "methodology.fluids.title",
                systemImage: "drop.fill"
            )
            Text(localized: "methodology.fluids.body")
                .font(DesignSystem.Typography.bodySecondary)
                .foregroundStyle(DesignSystem.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .fuelZoneCard()
    }

    private var referencesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FuelZoneSectionHeader(
                titleKey: "methodology.sources.title",
                subtitleKey: "methodology.sources.subtitle",
                systemImage: "doc.text"
            )
            ForEach(MethodologyReference.all) { reference in
                referenceCard(reference)
            }
        }
    }

    private func referenceCard(_ reference: MethodologyReference) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localized: reference.titleKey)
                .font(DesignSystem.Typography.cardTitle)
            Text(localized: reference.citationKey)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.textSecondary)
            Link(destination: reference.url) {
                Label {
                    Text(localized: "methodology.sources.open")
                } icon: {
                    Image(systemName: "arrow.up.right")
                }
                .font(DesignSystem.Typography.caption.weight(.medium))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fuelZoneCard()
    }

    private var disclaimerSection: some View {
        FuelZoneInfoBanner(message: String(localized: "methodology.disclaimer"), style: .info)
    }
}

private struct MethodologyReference: Identifiable {
    let id: String
    let titleKey: String
    let citationKey: String
    let url: URL

    static let all: [MethodologyReference] = [
        MethodologyReference(
            id: "jeukendrup2014",
            titleKey: "methodology.ref.jeukendrup.title",
            citationKey: "methodology.ref.jeukendrup.citation",
            url: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC4008807/")!
        ),
        MethodologyReference(
            id: "burke2011",
            titleKey: "methodology.ref.burke.title",
            citationKey: "methodology.ref.burke.citation",
            url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/21660838/")!
        ),
        MethodologyReference(
            id: "jeukendrup2000",
            titleKey: "methodology.ref.oxidation.title",
            citationKey: "methodology.ref.oxidation.citation",
            url: URL(string: "https://link.springer.com/article/10.2165/00007256-200029060-00004")!
        ),
        MethodologyReference(
            id: "gssi108",
            titleKey: "methodology.ref.mtc.title",
            citationKey: "methodology.ref.mtc.citation",
            url: URL(string: "https://www.gssiweb.org/en/sports-science-exchange/article/sse-108-multiple-transportable-carbohydrates-and-their-benefits")!
        ),
        MethodologyReference(
            id: "issn2017",
            titleKey: "methodology.ref.issn.title",
            citationKey: "methodology.ref.issn.citation",
            url: URL(string: "https://pubmed.ncbi.nlm.nih.gov/28919842/")!
        )
    ]
}
