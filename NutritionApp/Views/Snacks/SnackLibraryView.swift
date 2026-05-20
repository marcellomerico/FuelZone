import SwiftUI

struct SnackLibraryView: View {
    @ObservedObject var viewModel: SnackViewModel
    @State private var showAddCustom = false

    var body: some View {
        List {
            if let error = viewModel.loadError {
                Text(error).foregroundStyle(.red)
            }

            Picker(String(localized: "snack.library.filter"), selection: $viewModel.selectedCategory) {
                Text("—").tag(SnackCategory?.none)
                ForEach(SnackCategory.allCases) { cat in
                    Text(LocalizedEnum.label(for: cat)).tag(SnackCategory?.some(cat))
                }
            }

            ForEach(viewModel.filteredSnacks()) { snack in
                HStack {
                    Image(systemName: snack.category.systemImageName)
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading) {
                        Text(snack.localizedName)
                        Text("\(Int(snack.carbsPerServing)) g · \(Int(snack.sodiumMgPerServing)) mg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { viewModel.isEnabled(snack) },
                        set: { viewModel.setEnabled(snack, enabled: $0) }
                    ))
                    .labelsHidden()
                }
            }
        }
        .navigationTitle(Text(localized: "snack.library.title"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if viewModel.canAddCustom {
                        showAddCustom = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(!viewModel.canAddCustom)
            }
        }
        .sheet(isPresented: $showAddCustom) {
            AddCustomSnackView(viewModel: viewModel)
        }
    }
}
