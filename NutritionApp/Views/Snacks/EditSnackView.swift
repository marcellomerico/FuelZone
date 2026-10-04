import PhotosUI
import SwiftUI

/// Create or edit a custom snack (Pro).
struct EditSnackView: View {
    @ObservedObject var viewModel: SnackViewModel
    @Environment(\.dismiss) private var dismiss
    let existingSnack: Snack?

    @State private var nameEN = ""
    @State private var nameDE = ""
    @State private var category: SnackCategory = .gel
    @State private var nutritionBasis: SnackNutritionBasis = .perServing
    @State private var carbs = ""
    @State private var sodium = ""
    @State private var portionGrams = ""
    @State private var unitKey = "unit.piece"
    @State private var photoItem: PhotosPickerItem?
    @State private var photoImage: UIImage?
    @State private var removePhoto = false
    @State private var confirmDelete = false

    private static let unitKeys = [
        "unit.gel", "unit.bar", "unit.piece", "unit.pack", "unit.waffle", "unit.slice", "unit.handful",
        "unit.tbsp", "unit.scoop", "unit.tablet", "unit.capsule", "unit.bottle", "unit.ml500", "unit.ml330", "unit.ml250",
    ]

    private var isEditing: Bool { existingSnack != nil }
    private var carbsValue: Double? { InputParsing.nonNegative(carbs) }
    private var sodiumValid: Bool { sodium.trimmingCharacters(in: .whitespaces).isEmpty || InputParsing.nonNegative(sodium) != nil }
    private var canSave: Bool {
        !nameEN.trimmingCharacters(in: .whitespaces).isEmpty && carbsValue != nil && sodiumValid
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                    photoSection

                    VStack(alignment: .leading, spacing: 12) {
                        FZTextField(label: L10n.string("snack.addCustom.nameEN"), text: $nameEN, placeholder: "Energy Gel")
                        FZTextField(label: L10n.string("snack.addCustom.nameDE"), text: $nameDE, placeholder: L10n.string("snack.edit.optional"))
                        pickerRow(title: L10n.string("snack.addCustom.category")) {
                            Picker(L10n.string("snack.addCustom.category"), selection: $category) {
                                ForEach(SnackCategory.allCases) { Text(LocalizedEnum.label(for: $0)).tag($0) }
                            }
                        }
                        pickerRow(title: L10n.string("snack.addCustom.unit")) {
                            Picker(L10n.string("snack.addCustom.unit"), selection: $unitKey) {
                                ForEach(Self.unitKeys, id: \.self) { Text(L10n.string($0)).tag($0) }
                            }
                        }
                    }
                    .fzCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(localized: "snack.nutrition.basisTitle").fzLabelStyle()
                        FZSegmentedControl(
                            options: SnackNutritionBasis.allCases.map { .init(value: $0, title: L10n.string($0.localizationKey)) },
                            selection: $nutritionBasis
                        )
                        HStack(spacing: 10) {
                            FZTextField(
                                label: L10n.string(nutritionBasis == .per100g ? "snack.addCustom.carbsPer100g" : "snack.addCustom.carbsPerPortion"),
                                text: $carbs, placeholder: "25", unit: "g", keyboard: .decimalPad,
                                isInvalid: !carbs.isEmpty && carbsValue == nil
                            )
                            FZTextField(
                                label: L10n.string(nutritionBasis == .per100g ? "snack.addCustom.sodiumPer100g" : "snack.addCustom.sodiumPerPortion"),
                                text: $sodium, placeholder: "50", unit: "mg", keyboard: .decimalPad,
                                isInvalid: !sodiumValid
                            )
                        }
                        if nutritionBasis == .per100g {
                            FZTextField(
                                label: L10n.string(category == .drink ? "snack.addCustom.portionMl" : "snack.addCustom.portionGrams"),
                                text: $portionGrams, placeholder: category == .drink ? "500" : "40",
                                unit: category == .drink ? "ml" : "g", keyboard: .decimalPad
                            )
                        }
                    }
                    .fzCard()

                    if isEditing {
                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            Text(localized: "snack.edit.delete")
                                .font(Theme.Typography.bodyEmphasis)
                                .foregroundStyle(Theme.Colors.danger)
                                .frame(maxWidth: .infinity, minHeight: Theme.minTouch)
                        }
                    }
                }
                .padding(Theme.Spacing.screen)
            }
            .scrollDismissesKeyboard(.interactively)
            .fzScreenBackground()
            .navigationTitle(Text(localized: isEditing ? "snack.edit.title" : "snack.addCustom.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text(localized: "common.cancel") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { save() } label: { Text(localized: "common.save").bold() }
                        .disabled(!canSave)
                }
            }
            .confirmationDialog(Text(localized: "snack.edit.delete.confirm"), isPresented: $confirmDelete, titleVisibility: .visible) {
                Button(role: .destructive) { deleteSnack() } label: { Text(localized: "snack.edit.delete") }
            }
            .onAppear(perform: loadExisting)
            .onChange(of: photoItem) { _, item in
                Task { await loadPhoto(from: item) }
            }
        }
    }

    private func pickerRow<P: View>(title: String, @ViewBuilder picker: () -> P) -> some View {
        HStack {
            Text(title).font(Theme.Typography.subheadlineEmphasis).foregroundStyle(Theme.Colors.ink)
            Spacer()
            picker().pickerStyle(.menu).tint(Theme.Colors.accentText)
        }
        .frame(minHeight: Theme.minTouch)
    }

    private var photoSection: some View {
        HStack(spacing: 14) {
            Group {
                if let photoImage {
                    Image(uiImage: photoImage).resizable().scaledToFill()
                } else {
                    Image(systemName: "photo").font(.title2).foregroundStyle(Theme.Colors.ink3)
                }
            }
            .frame(width: 76, height: 76)
            .background(Theme.Colors.surface2)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Text(localized: "snack.photo.choose").font(Theme.Typography.bodyEmphasis).foregroundStyle(Theme.Colors.accentText)
                        .frame(minHeight: Theme.minTouch)
                }
                if photoImage != nil {
                    Button {
                        photoImage = nil
                        removePhoto = true
                        photoItem = nil
                    } label: {
                        Text(localized: "snack.photo.remove").font(Theme.Typography.footnote).foregroundStyle(Theme.Colors.danger)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .fzCard()
    }

    private func loadExisting() {
        guard let snack = existingSnack else { return }
        nameEN = snack.nameEN ?? snack.localizedName
        nameDE = snack.nameDE ?? ""
        category = snack.category
        nutritionBasis = snack.nutritionBasis
        carbs = snack.carbsPerServing.formatted(.number.precision(.fractionLength(0...1)))
        sodium = snack.sodiumMgPerServing.formatted(.number.precision(.fractionLength(0...1)))
        portionGrams = snack.defaultPortionGrams.map { $0.formatted(.number.precision(.fractionLength(0))) } ?? ""
        unitKey = Self.unitKeys.contains(snack.unitKey) ? snack.unitKey : "unit.piece"
        photoImage = SnackPhotoStore.load(snackID: snack.id)
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else { return }
        photoImage = image
        removePhoto = false
    }

    private func save() {
        guard let carbsValue else { return }
        let snackID = existingSnack?.id ?? UUID()
        let trimmedEN = nameEN.trimmingCharacters(in: .whitespaces)
        let trimmedDE = nameDE.trimmingCharacters(in: .whitespaces)
        let portion = InputParsing.nonNegative(portionGrams).flatMap { $0 > 0 ? $0 : nil }
        let snack = Snack(
            id: snackID,
            nameEN: trimmedEN,
            nameDE: trimmedDE.isEmpty ? trimmedEN : trimmedDE,
            category: category,
            carbsPerServing: carbsValue,
            sodiumMgPerServing: InputParsing.nonNegative(sodium) ?? 0,
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
        viewModel.saveCustomSnack(snack, isNew: !isEditing)
        dismiss()
    }

    private func deleteSnack() {
        guard let existingSnack else { return }
        viewModel.deleteCustomSnack(existingSnack)
        dismiss()
    }
}
