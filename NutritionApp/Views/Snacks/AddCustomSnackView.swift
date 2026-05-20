import SwiftUI

struct AddCustomSnackView: View {
    @ObservedObject var viewModel: SnackViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var nameEN = ""
    @State private var nameDE = ""
    @State private var category: SnackCategory = .other
    @State private var carbs = ""
    @State private var sodium = ""
    @State private var unitKey = "unit.piece"

    var body: some View {
        NavigationStack {
            Form {
                TextField(String(localized: "snack.addCustom.nameEN"), text: $nameEN)
                TextField(String(localized: "snack.addCustom.nameDE"), text: $nameDE)
                Picker(String(localized: "snack.addCustom.category"), selection: $category) {
                    ForEach(SnackCategory.allCases) { cat in
                        Text(LocalizedEnum.label(for: cat)).tag(cat)
                    }
                }
                TextField(String(localized: "snack.addCustom.carbs"), text: $carbs)
                    .keyboardType(.decimalPad)
                TextField(String(localized: "snack.addCustom.sodium"), text: $sodium)
                    .keyboardType(.decimalPad)
                TextField(String(localized: "snack.addCustom.unit"), text: $unitKey)
            }
            .navigationTitle(Text(localized: "snack.addCustom.title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text(localized: "onboarding.button.back") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { save() } label: { Text(localized: "snack.addCustom.save") }
                        .disabled(nameEN.isEmpty || carbs.isEmpty)
                }
            }
        }
    }

    private func save() {
        guard let carbsValue = Double(carbs.replacingOccurrences(of: ",", with: ".")) else { return }
        let sodiumValue = Double(sodium.replacingOccurrences(of: ",", with: ".")) ?? 0
        let snack = Snack(
            nameEN: nameEN,
            nameDE: nameDE.isEmpty ? nameEN : nameDE,
            category: category,
            carbsPerServing: carbsValue,
            sodiumMgPerServing: sodiumValue,
            unitKey: unitKey,
            isBuiltIn: false
        )
        viewModel.addCustomSnack(snack)
        dismiss()
    }
}
