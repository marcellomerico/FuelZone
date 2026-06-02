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
            FuelZoneScreenScroll {
                VStack(alignment: .leading, spacing: 14) {
                    FuelZoneSectionHeader(
                        titleKey: "snack.addCustom.title",
                        subtitleKey: "snack.addCustom.subtitle",
                        systemImage: "plus.circle"
                    )
                    FuelZoneLabeledField(labelKey: "snack.addCustom.nameEN", text: $nameEN, keyboardType: .default)
                    FuelZoneLabeledField(labelKey: "snack.addCustom.nameDE", text: $nameDE, keyboardType: .default)
                    Text(localized: "snack.addCustom.category")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.textSecondary)
                    Picker("", selection: $category) {
                        ForEach(SnackCategory.allCases) { cat in
                            Text(LocalizedEnum.label(for: cat)).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    FuelZoneLabeledField(labelKey: "snack.addCustom.carbs", text: $carbs)
                    FuelZoneLabeledField(labelKey: "snack.addCustom.sodium", text: $sodium)
                    FuelZoneLabeledField(labelKey: "snack.addCustom.unit", text: $unitKey, keyboardType: .default)
                }
                .fuelZoneCard()

                Button { save() } label: {
                    Text(localized: "snack.addCustom.save")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(nameEN.isEmpty || carbs.isEmpty)
            }
            .navigationTitle(Text(localized: "snack.addCustom.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    FuelZoneTextButton(titleKey: "onboarding.button.back") { dismiss() }
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
