import SwiftUI
import VisionKit

struct SnackLibraryView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: SnackViewModel
    @State private var showAddSnack = false

    private var snacks: [Snack] { viewModel.filteredSnacks() }

    var body: some View {
        FuelZoneScreenScroll {
            FuelZoneSnackFilterChips(selectedCategory: $viewModel.selectedCategory)

            Text(localized: "snack.library.listHint")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.textSecondary)
                .padding(.horizontal, 2)

            snackListSection
        }
        .navigationTitle(Text(localized: "snack.library.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DesignSystem.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { viewModel.requestBarcodeScan() } label: {
                    Image(systemName: "barcode.viewfinder")
                        .foregroundStyle(DesignSystem.accent)
                }
                .accessibilityLabel(Text(localized: "snack.scanBarcode"))

                Button {
                    if viewModel.requestAddCustomSnack() {
                        showAddSnack = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(DesignSystem.accentOnAmber)
                        .frame(width: 34, height: 34)
                        .background(DesignSystem.accent)
                        .clipShape(Circle())
                }
                .accessibilityLabel(Text(localized: "snack.addCustom.title"))
            }
        }
        .sheet(isPresented: $showAddSnack) {
            EditSnackView(viewModel: viewModel, existingSnack: nil)
        }
        .sheet(item: $viewModel.snackBeingEdited) { snack in
            EditSnackView(viewModel: viewModel, existingSnack: snack)
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
            ProPaywallSheet { appState.selectedTab = 3 }
                .environmentObject(appState)
        }
    }

    private var snackListSection: some View {
        VStack(spacing: 0) {
            if snacks.isEmpty {
                Text(localized: "snack.library.empty")
                    .font(DesignSystem.Typography.bodySecondary)
                    .foregroundStyle(DesignSystem.textSecondary)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(Array(snacks.enumerated()), id: \.element.id) { index, snack in
                    FuelZoneSnackRowStyled(
                        snack: snack,
                        photo: SnackPhotoStore.load(snackID: snack.id),
                        isEnabled: viewModel.isEnabled(snack),
                        onToggle: { viewModel.setEnabled(snack, enabled: $0) },
                        onTap: { openEditor(for: snack) }
                    )
                    if index < snacks.count - 1 {
                        FuelZoneCardDivider()
                    }
                }
            }
        }
        .fuelZoneCard(padding: 6)
    }

    private func openEditor(for snack: Snack) {
        guard !snack.isBuiltIn else { return }
        guard viewModel.canEditCustom else {
            viewModel.showProPaywall = true
            return
        }
        viewModel.snackBeingEdited = snack
    }
}
