import SwiftUI

/// Science & methodology: how the plan is built, with sources.
struct FuelingMethodologyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                Text(localized: "methodology.hero.subtitle")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.ink2)
                    .fixedSize(horizontal: false, vertical: true)

                textCard(titleKey: "methodology.why.title", bodyKey: "methodology.why.body")

                VStack(alignment: .leading, spacing: 14) {
                    Text(localized: "methodology.how.title").font(Theme.Typography.sectionTitle)
                    ForEach(1...4, id: \.self) { number in
                        HStack(alignment: .top, spacing: 14) {
                            Text("\(number)")
                                .font(.headline.weight(.heavy).width(.compressed))
                                .foregroundStyle(Theme.Colors.onInk)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Theme.Colors.ink))
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(localized: "methodology.step\(number).title").font(Theme.Typography.bodyEmphasis)
                                Text(localized: "methodology.step\(number).body")
                                    .font(Theme.Typography.subheadline)
                                    .foregroundStyle(Theme.Colors.ink2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .fzCard()

                FZSectionHeader(title: L10n.string("methodology.tiers.title"), trailing: nil)
                    .padding(.top, 6)
                tierCard(durationKey: "methodology.tier.short.duration", amount: 30, tipKey: "methodology.tier.short.tip")
                tierCard(durationKey: "methodology.tier.medium.duration", amount: 60, tipKey: "methodology.tier.medium.tip")
                tierCard(durationKey: "methodology.tier.long.duration", amount: 90, tipKey: "methodology.tier.long.tip")

                VStack(alignment: .leading, spacing: 10) {
                    Text(localized: "methodology.adjustments.title").font(Theme.Typography.sectionTitle)
                    bullet("methodology.adjustment.intensity.body")
                    bullet("methodology.adjustment.stomach.body")
                }
                .fzCard()

                textCard(titleKey: "methodology.fluids.title", bodyKey: "methodology.fluids.body")

                FZSectionHeader(title: L10n.string("methodology.sources.title"), trailing: nil)
                    .padding(.top, 6)
                ForEach(MethodologyReference.all) { reference in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(localized: reference.titleKey).font(Theme.Typography.bodyEmphasis)
                        Text(localized: reference.citationKey)
                            .font(Theme.Typography.footnote)
                            .foregroundStyle(Theme.Colors.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                        Link(destination: reference.url) {
                            Label { Text(localized: "methodology.sources.open") } icon: { Image(systemName: "arrow.up.right") }
                                .font(Theme.Typography.subheadlineEmphasis)
                                .foregroundStyle(Theme.Colors.accentText)
                                .frame(minHeight: Theme.minTouch)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fzCard()
                }

                FZBanner(message: L10n.string("methodology.disclaimer"))
            }
            .padding(Theme.Spacing.screen)
        }
        .fzScreenBackground()
        .navigationTitle(Text(localized: "methodology.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func textCard(titleKey: String, bodyKey: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localized: titleKey).font(Theme.Typography.sectionTitle)
            Text(localized: bodyKey)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fzCard()
    }

    private func tierCard(durationKey: String, amount: Int, tipKey: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(localized: durationKey).font(Theme.Typography.bodyEmphasis)
                Text(localized: tipKey)
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Colors.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                MetricText("~\(amount)", size: 40, color: Theme.Nutrient.carbs.color, relativeTo: .title)
                Text("g/h").font(Theme.Typography.caption.weight(.bold)).foregroundStyle(Theme.Nutrient.carbs.color)
            }
        }
        .fzCard()
        .accessibilityElement(children: .combine)
    }

    private func bullet(_ key: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Circle().fill(Theme.Colors.accentFill).frame(width: 7, height: 7).accessibilityHidden(true)
            Text(localized: key)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
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
