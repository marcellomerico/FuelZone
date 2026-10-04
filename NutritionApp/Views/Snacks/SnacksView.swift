import SwiftUI
import VisionKit

/// Snacks tab: “My kit” (what the planner uses) and the catalog to add from.
struct SnacksView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: SnackViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                FZScreenHeader(eyebrow: L10n.string("snacks.eyebrow"), title: L10n.string("tab.snacks")) {
                    addMenu
                }
                .padding(.horizontal, Theme.Spacing.screen)

                if let error = viewModel.loadError {
                    FZBanner(message: error, style: .warning).padding(.horizontal, Theme.Spacing.screen)
                }

                kitSection
                catalogSection

                if !viewModel.canManageCustomSnacks {
                    proHint.padding(.horizontal, Theme.Spacing.screen)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .fzScreenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $viewModel.showAddSnack) {
            EditSnackView(viewModel: viewModel, existingSnack: nil)
        }
        .sheet(item: $viewModel.snackBeingEdited) { snack in
            EditSnackView(viewModel: viewModel, existingSnack: snack)
        }
        .sheet(isPresented: $viewModel.showBarcodeScanner) {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                BarcodeScannerScreen(snackViewModel: viewModel)
            } else {
                ContentUnavailableView(L10n.string("error.barcodeUnavailable"), systemImage: "barcode.viewfinder")
                    .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $viewModel.showProPaywall) {
            PaywallView()
        }
    }

    private var addMenu: some View {
        Menu {
            Button {
                viewModel.requestAddCustomSnack()
            } label: {
                Label { Text(localized: "snacks.add.manual") } icon: { Image(systemName: "square.and.pencil") }
            }
            Button {
                viewModel.requestBarcodeScan()
            } label: {
                Label { Text(localized: "snack.scanBarcode") } icon: { Image(systemName: "barcode.viewfinder") }
            }
        } label: {
            Image(systemName: "plus")
                .font(.body.weight(.bold))
                .foregroundStyle(Theme.Colors.onInk)
                .frame(width: Theme.minTouch, height: Theme.minTouch)
                .background(Circle().fill(Theme.Colors.ink))
        }
        .accessibilityLabel(Text(localized: "snack.addCustom.title"))
    }

    // MARK: Kit

    private var kitSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            FZSectionHeader(title: L10n.string("snacks.kit"), trailing: L10n.string("snacks.kit.hint"))
                .padding(.horizontal, Theme.Spacing.screen)
            if viewModel.kitSnacks.isEmpty {
                FZBanner(message: L10n.string("snacks.kit.empty"))
                    .padding(.horizontal, Theme.Spacing.screen)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.kitSnacks) { snack in
                            KitCard(snack: snack) {
                                viewModel.toggleKit(snack)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.screen)
                }
            }
        }
    }

    // MARK: Catalog

    private var catalogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FZSectionHeader(title: L10n.string("snacks.catalog"))
                .padding(.horizontal, Theme.Spacing.screen)
                .padding(.top, 6)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.Colors.ink2)
                TextField(L10n.string("snacks.search"), text: $viewModel.searchText)
                    .font(Theme.Typography.body)
                    .submitLabel(.search)
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.Colors.ink3)
                    }
                    .accessibilityLabel(Text(localized: "common.clear"))
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: Theme.minTouch)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.Colors.surface2))
            .padding(.horizontal, Theme.Spacing.screen)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    FZChip(title: L10n.string("snack.library.all"), isSelected: viewModel.selectedCategory == nil, height: 36) {
                        viewModel.selectedCategory = nil
                    }
                    ForEach(SnackCategory.allCases.sorted { $0.sortOrder < $1.sortOrder }) { category in
                        FZChip(
                            title: LocalizedEnum.label(for: category),
                            isSelected: viewModel.selectedCategory == category,
                            height: 36
                        ) {
                            viewModel.selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.screen)
            }

            let snacks = viewModel.catalogSnacks
            VStack(spacing: 0) {
                if snacks.isEmpty {
                    Text(localized: "snack.library.empty")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.ink2)
                        .frame(maxWidth: .infinity, minHeight: 60)
                }
                ForEach(Array(snacks.enumerated()), id: \.element.id) { index, snack in
                    HStack(spacing: 10) {
                        Button {
                            viewModel.requestEdit(snack)
                        } label: {
                            SnackRow(snack: snack)
                        }
                        .buttonStyle(.plain)
                        .disabled(snack.isBuiltIn)

                        KitToggleButton(isInKit: viewModel.isInKit(snack), name: snack.localizedName) {
                            viewModel.toggleKit(snack)
                        }
                    }
                    .padding(.vertical, 8)
                    if index < snacks.count - 1 {
                        Divider().overlay(Theme.Colors.line)
                    }
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 8)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous).fill(Theme.Colors.surface))
            .padding(.horizontal, Theme.Spacing.screen)
        }
    }

    private var proHint: some View {
        Button {
            viewModel.showProPaywall = true
        } label: {
            HStack(spacing: 12) {
                FZIconTile(systemImage: "star.fill", foreground: Theme.Colors.onAccent, background: Theme.Colors.accentFill, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(localized: "snacks.pro.title").font(Theme.Typography.subheadlineEmphasis).foregroundStyle(Theme.Colors.ink)
                    Text(localized: "snacks.pro.subtitle").font(Theme.Typography.footnote).foregroundStyle(Theme.Colors.ink2)
                }
                Spacer()
                Text(localized: "common.view").font(Theme.Typography.subheadlineEmphasis).foregroundStyle(Theme.Colors.accentText)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.Colors.line, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
        }
        .buttonStyle(.plain)
    }
}

/// Card in the horizontal “My kit” row.
private struct KitCard: View {
    let snack: Snack
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                SnackIcon(snack: snack, size: 48)
                Spacer()
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.Colors.ink3)
                        .frame(width: Theme.minTouch, height: Theme.minTouch, alignment: .topTrailing)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(L10n.format("snacks.kit.remove", snack.localizedName)))
            }
            Text(snack.localizedName)
                .font(Theme.Typography.subheadlineEmphasis)
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(2, reservesSpace: true)
            HStack(spacing: 12) {
                miniMetric(FZFormat.integer(snack.carbsPerDefaultPortion), L10n.string("unit.carbs.short"), .carbs)
                miniMetric(FZFormat.integer(snack.sodiumMgPerDefaultPortion), L10n.string("unit.sodium.short"), .sodium)
            }
        }
        .frame(width: 150, alignment: .leading)
        .fzCard(padding: 14)
        .accessibilityElement(children: .contain)
    }

    private func miniMetric(_ value: String, _ unit: String, _ nutrient: Theme.Nutrient) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            MetricText(value, size: 26, color: nutrient.color, relativeTo: .title3)
            Text(unit).font(.caption2.weight(.semibold)).foregroundStyle(Theme.Colors.ink2)
        }
    }
}

/// Add/remove a snack from the kit (+ / ✓), 44 pt.
private struct KitToggleButton: View {
    let isInKit: Bool
    let name: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isInKit ? "checkmark" : "plus")
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(isInKit ? Theme.Colors.onInk : Theme.Colors.ink)
                .frame(width: Theme.minTouch, height: Theme.minTouch)
                .background(
                    Circle()
                        .fill(isInKit ? Theme.Colors.ink : Color.clear)
                        .overlay(Circle().stroke(isInKit ? Color.clear : Theme.Colors.line))
                )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isInKit)
        .accessibilityLabel(Text(L10n.format(isInKit ? "snacks.kit.remove" : "snacks.kit.add", name)))
        .accessibilityAddTraits(isInKit ? .isSelected : [])
    }
}

/// Snack icon or photo in a tinted tile.
struct SnackIcon: View {
    let snack: Snack
    var size: CGFloat = 40

    var body: some View {
        let nutrient = PlanPresentation.nutrient(for: snack)
        if let photo = snack.isBuiltIn ? nil : SnackPhotoStore.load(snackID: snack.id) {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
                .accessibilityHidden(true)
        } else {
            FZIconTile(
                systemImage: PlanPresentation.icon(for: snack),
                foreground: nutrient.color,
                background: nutrient.tint,
                size: size
            )
        }
    }
}

/// Catalog row: icon, name and carb/sodium bars.
struct SnackRow: View {
    let snack: Snack

    var body: some View {
        HStack(spacing: 12) {
            SnackIcon(snack: snack)
            VStack(alignment: .leading, spacing: 6) {
                Text(snack.localizedName)
                    .font(Theme.Typography.bodyEmphasis)
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(1)
                HStack(spacing: 10) {
                    bar(value: snack.carbsPerDefaultPortion, max: 80, label: "\(FZFormat.integer(snack.carbsPerDefaultPortion)) g", nutrient: .carbs)
                    bar(value: snack.sodiumMgPerDefaultPortion, max: 400, label: "\(FZFormat.integer(snack.sodiumMgPerDefaultPortion)) mg", nutrient: .sodium)
                }
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.format(
            "a11y.snack",
            snack.localizedName,
            FZFormat.integer(snack.carbsPerDefaultPortion),
            FZFormat.integer(snack.sodiumMgPerDefaultPortion)
        )))
    }

    private func bar(value: Double, max maxValue: Double, label: String, nutrient: Theme.Nutrient) -> some View {
        HStack(spacing: 6) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.Colors.surface2)
                    Capsule().fill(nutrient.color).frame(width: proxy.size.width * min(1, value / maxValue))
                }
            }
            .frame(height: 5)
            Text(label)
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(nutrient.color)
                .fixedSize()
        }
    }
}
