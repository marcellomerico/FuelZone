import SwiftUI
import VisionKit

struct BarcodeScannerView: UIViewControllerRepresentable {
    let onBarcode: (String) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        context.coordinator.parent = self
        guard !uiViewController.isScanning else { return }
        try? uiViewController.startScanning()
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: BarcodeScannerView

        init(parent: BarcodeScannerView) {
            self.parent = parent
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            process(item)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard let item = addedItems.first else { return }
            process(item)
        }

        private func process(_ item: RecognizedItem) {
            if case .barcode(let barcode) = item {
                parent.onBarcode(barcode.payloadStringValue ?? "")
            }
        }
    }
}

struct BarcodeScannerScreen: View {
    @ObservedObject var snackViewModel: SnackViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                BarcodeScannerView(
                    onBarcode: { code in
                        Task { await handleBarcode(code) }
                    },
                    onCancel: { dismiss() }
                )
                .ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .navigationTitle(Text(localized: "snack.scanBarcode"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .alert(Text(localized: "error.title"), isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button(role: .cancel) {} label: {
                    Text(localized: "onboarding.button.back")
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    @MainActor
    private func handleBarcode(_ code: String) async {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let nutrition = try await OpenFoodFactsClient.fetchProduct(barcode: trimmed)
            let snack = Snack(
                nameEN: nutrition.nameEN,
                nameDE: nutrition.nameDE,
                category: .other,
                carbsPerServing: nutrition.carbsPerServing,
                sodiumMgPerServing: nutrition.sodiumMgPerServing,
                unitKey: "unit.piece",
                isBuiltIn: false,
                barcode: nutrition.barcode
            )
            snackViewModel.addCustomSnack(snack)
            dismiss()
        } catch {
            errorMessage = String(localized: "error.barcodeNotFound")
        }
    }
}
