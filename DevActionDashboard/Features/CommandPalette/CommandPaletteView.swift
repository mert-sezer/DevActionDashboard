import SwiftUI

struct CommandPaletteView: View {
    let items: [CommandPaletteItem]
    let onSelect: (CommandPaletteItem) -> Void
    let onDismiss: () -> Void

    @State private var query = ""
    @State private var selection: String?
    @FocusState private var isSearchFocused: Bool

    private var filtered: [CommandPaletteItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return items }
        return items.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.subtitle.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search features, utilities, actions…", text: $query)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .onSubmit(activateSelection)
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close")
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)

            Divider()

            if filtered.isEmpty {
                ContentUnavailableView(
                    "No matches",
                    systemImage: "magnifyingglass",
                    description: Text("Try another keyword.")
                )
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                List(filtered, selection: $selection) { item in
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: item.symbolName)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(DesignTokens.Typography.body.weight(.medium))
                            Text(item.subtitle)
                                .font(DesignTokens.Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .tag(item.id)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(item)
                    }
                }
                .listStyle(.plain)
                .frame(maxHeight: 360)
            }
        }
        .frame(width: 560)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sheet, style: .continuous)
                .fill(DesignTokens.Colors.card.opacity(0.96))
                .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.sheet, style: .continuous))
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sheet, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sheet, style: .continuous)
                .strokeBorder(DesignTokens.Colors.outlineVariant.opacity(0.7), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 28, y: 12)
        .onAppear {
            isSearchFocused = true
            selection = filtered.first?.id
        }
        .onChange(of: query) { _, _ in
            selection = filtered.first?.id
        }
    }

    private func activateSelection() {
        if let selection,
           let item = filtered.first(where: { $0.id == selection }) {
            onSelect(item)
        } else if let first = filtered.first {
            onSelect(first)
        }
    }
}
