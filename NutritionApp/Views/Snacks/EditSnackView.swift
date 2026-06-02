import PhotosUI
import SwiftUI

struct EditSnackView: View {
    @ObservedObject var viewModel: SnackViewModel
    @Environment(\.dismiss) private var dismiss

    let existingSnack: Snack?

    @State private var nameEN = ""
    @State private var nameDE = ""
    @State private var category: SnackCategory = .other
    @State private var nutritionBasis: SnackNutritionBasis = .per100g
    @State private var carbs = ""
    @State private var sodium = ""
    @State private var portionGrams = ""
    @State private var unitKey = "unit.piece"
    @State private var photoItem: PhotosPickerItem?
    @State private var photoImage: UIImage?
    @State private var removePhoto = false

    private var isEditing: Bool { existingSnack != nil }

    private var carbsLabelKey: String {
        nutritionBasis == .per100g ? "snack.addCustom.carbsPer100g" : "snack.addCustom.carbsPerPortion"
    }

    private var sodiumLabelKey: String {
        nutritionBasis == .per100g ? "snack.addCustom.sodiumPer100g" : "snack.addCustom.sodiumPerPortion"
    }

    var body: some View {
        NavigationStack {
            FuelZoneScreenScroll {
                VStack(alignment: .leading, spacing: 14) {
                    FuelZoneSectionHeader(
                        titleKey: isEditing ? "snack.edit.title" : "snack.addCustom.title",
                        subtitleKey: isEditing ? "snack.edit.subtitle" : "snack.addCustom.subtitle",
                        systemImage: "fork.knife"
                    )

                    photoSection

                    FuelZoneLabeledField(labelKey: "snack.addCustom.nameEN", text: $nameEN, keyboardType: .default)
                    FuelZoneLabeledField(labelKey: "snack.addCustom.nameDE", text: $nameDE, keyboardType: .default)
                    Text(localized: "snack.addCustom.category")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.textSecondary)
                    Picker("", selection: $category) {
                        ForEach(SnackCategory.allCases) { cat in
                            Text(localized: LocalizedEnum.key(for: cat)).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)

                    Text(localized: "snack.nutrition.basisTitle")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.textSecondary)
                    Picker("", selection: $nutritionBasis) {
                        ForEach(SnackNutritionBasis.allCases) { basis in
                            Text(localized: basis.localizationKey).tag(basis)
                        }
                    }
                    .pickerStyle(.segmented)

                    FuelZoneLabeledField(labelKey: carbsLabelKey, text: $carbs)
                    FuelZoneLabeledField(labelKey: sodiumLabelKey, text: $sodium)

                    if nutritionBasis == .per100g {
                        FuelZoneLabeledField(
                            labelKey: "snack.addCustom.portionGrams",
                            text: $portionGrams
                        )
                    }

                    FuelZoneLabeledField(labelKey: "snack.addCustom.unit", text: $unitKey, keyboardType: .default)
                }
                .fuelZoneCard()

                Button { save() } label: {
                    Text(localized: isEditing ? "snack.edit.save" : "snack.addCustom.save")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(nameEN.isEmpty || carbs.isEmpty)

                if isEditing {
                    Button(role: .destructive) { deleteSnack() } label: {
                        Text(localized: "snack.edit.delete")
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 4)
                }
            }
            .navigationTitle(Text(localized: isEditing ? "snack.edit.title" : "snack.addCustom.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    FuelZoneTextButton(titleKey: "onboarding.button.back") { dismiss() }
                }
            }
            .onAppear(perform: loadExisting)
            .onChange(of: photoItem) { _, item in
                Task { await loadPhoto(from: item) }
            }
        }
    }

    @ViewBuilder
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localized: "snack.photo.title")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.textSecondary)

            HStack(spacing: 14) {
                Group {
                    if let photoImage {
                        Image(uiImage: photoImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(DesignSystem.textSecondary)
                    }
                }
                .frame(width: 72, height: 72)
                .background(DesignSystem.embeddedTrack)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Text(localized: "snack.photo.choose")
                            .font(DesignSystem.Typography.cardTitle)
                            .foregroundStyle(Color.accentColor)
                    }
                    if photoImage != nil {
                        Button { photoImage = nil; removePhoto = true; photoItem = nil } label: {
                            Text(localized: "snack.photo.remove")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func loadExisting() {
        guard let snack = existingSnack else { return }
        nameEN = snack.nameEN ?? ""
        nameDE = snack.nameDE ?? ""
        category = snack.category
        nutritionBasis = snack.nutritionBasis
        carbs = String(snack.carbsPerServing)
        sodium = String(snack.sodiumMgPerServing)
        portionGrams = snack.defaultPortionGrams.map { String(format: "%.0f", $0) } ?? ""
        unitKey = snack.unitKey
        photoImage = SnackPhotoStore.load(snackID: snack.id)
        removePhoto = false
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            await MainActor.run {
                photoImage = image
                removePhoto = false
            }
        }
    }

    private func save() {
        guard let carbsValue = Double(carbs.replacingOccurrences(of: ",", with: ".")) else { return }
        let sodiumValue = Double(sodium.replacingOccurrences(of: ",", with: ".")) ?? 0
        let snackID = existingSnack?.id ?? UUID()
        let portion = Double(portionGrams.replacingOccurrences(of: ",", with: "."))
        let snack = Snack(
            id: snackID,
            nameEN: nameEN,
            nameDE: nameDE.isEmpty ? nameEN : nameDE,
            category: category,
            carbsPerServing: carbsValue,
            sodiumMgPerServing: sodiumValue,
            nutritionBasis: nutritionBasis,
            defaultPortionGrams: nutritionBasis == .per100g ? portion : nil,
            unitKey: unitKey,
            isBuiltIn: false,
            barcode: existingSnack?.barcode
        )

        if let photoImage, !removePhoto {
            try? SnackPhotoStore.save(image: photoImage, snackID: snackID)
        } else if removePhoto {
            SnackPhotoStore.delete(snackID: snackID)
        }

        if isEditing {
            viewModel.updateCustomSnack(snack)
        } else {
            viewModel.addCustomSnack(snack)
        }
        dismiss()
    }

    private func deleteSnack() {
        guard let existingSnack else { return }
        viewModel.deleteCustomSnack(existingSnack)
        dismiss()
    }
}
