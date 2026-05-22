import SwiftUI
import VisionKit

struct SnackLibraryView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: SnackViewModel
    @State private var showAddCustom = false

    private var snacks: [Snack] { viewModel.filteredSnacks() }

    var body: some View {
        FuelZoneScreenScroll {
            if let error = viewModel.loadError {
                FuelZoneInfoBanner(message: error, style: .warning)
            }

            filterSection
            snackListSection
        }
        .navigationTitle(Text(localized: "snack.library.title"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { viewModel.requestBarcodeScan() } label: {
                    Image(systemName: "barcode.viewfinder")
                }
                Button {
                    if viewModel.canAddCustom {
                        showAddCustom = true
                    } else {
                        viewModel.showProPaywall = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddCustom) {
            AddCustomSnackView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showBarcodeScanner) {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                BarcodeScannerScreen(snackViewModel: viewModel)
            } else {
                FuelZoneInfoBanner(message: String(localized: "error.barcodeUnavailable"), style: .warning)
                    .padding()
            }
        }
        .sheet(isPresented: $viewModel.showProPaywall) {
            ProPaywallSheet { appState.selectedTab = 2 }
        }
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FuelZoneSectionHeader(
                titleKey: "snack.library.filter",
                subtitleKey: "snack.library.filterHint",
                systemImage: "line.3.horizontal.decrease.circle"
            )
            Picker("", selection: $viewModel.selectedCategory) {
                Text(localized: "snack.library.all").tag(SnackCategory?.none)
                ForEach(SnackCategory.allCases) { cat in
                    Text(LocalizedEnum.label(for: cat)).tag(SnackCategory?.some(cat))
                }
            }
            .pickerStyle(.menu)
        }
        .fuelZoneCard()
    }

    private var snackListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            FuelZoneSectionHeader(
                titleKey: "snack.library.listTitle",
                subtitleKey: "snack.library.listHint",
                systemImage: "fork.knife"
            )
            .padding(.bottom, 12)

            if snacks.isEmpty {
                Text(localized: "snack.library.empty")
                    .font(DesignSystem.Typography.bodySecondary)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(snacks.enumerated()), id: \.element.id) { index, snack in
                    FuelZoneSnackRow(
                        snack: snack,
                        showsToggle: true,
                        isEnabled: viewModel.isEnabled(snack),
                        onToggle: { viewModel.setEnabled(snack, enabled: $0) }
                    )
                    if index < snacks.count - 1 {
                        FuelZoneCardDivider()
                    }
                }
            }
        }
        .fuelZoneCard()
    }
}
