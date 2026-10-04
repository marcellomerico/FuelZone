import SwiftUI

/// Pick a replacement snack for one stop. Kit snacks come first.
struct SnackSwapSheet: View {
    let snacks: [Snack]
    let kitIDs: Set<UUID>
    let onSelect: (Snack) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filtered: [Snack] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return snacks }
        return snacks.filter { $0.localizedName.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            List {
                let kit = filtered.filter { kitIDs.contains($0.id) }
                let others = filtered.filter { !kitIDs.contains($0.id) }
                if !kit.isEmpty {
                    Section { rows(kit) } header: { Text(localized: "snacks.kit") }
                }
                if !others.isEmpty {
                    Section { rows(others) } header: { Text(localized: "snacks.catalog") }
                }
                if filtered.isEmpty {
                    Text(localized: "snack.swap.empty").foregroundStyle(Theme.Colors.ink2)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .fzScreenBackground()
            .searchable(text: $searchText, prompt: Text(localized: "snack.swap.search"))
            .navigationTitle(Text(localized: "snack.swap.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text(localized: "common.cancel") }
                }
            }
        }
    }

    private func rows(_ items: [Snack]) -> some View {
        ForEach(items) { snack in
            Button {
                onSelect(snack)
                dismiss()
            } label: {
                SnackRow(snack: snack)
            }
            .buttonStyle(.plain)
            .listRowBackground(Theme.Colors.surface)
        }
    }
}
