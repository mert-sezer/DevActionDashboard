import SwiftUI

struct UtilitiesView: View {
    @Bindable private var navigation: AppNavigationStore
    @State private var selectedTool: UtilityTool = .uuid

    init(navigation: AppNavigationStore) {
        self.navigation = navigation
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 252)

            Rectangle()
                .fill(DesignTokens.Colors.outlineVariant.opacity(0.4))
                .frame(width: 1)
                .padding(.vertical, 0)

            detail
        }
        .onAppear(perform: applyPendingUtility)
        .onChange(of: navigation.pendingUtilityTool) { _, _ in
            applyPendingUtility()
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Utilities")
                    .font(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Colors.onSurface)
                    .accessibilityAddTraits(.isHeader)
                Text("\(UtilityTool.allCases.count) tools")
                    .font(DesignTokens.Typography.monoCaption)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.top, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.sm)

            Rectangle()
                .fill(DesignTokens.Colors.outlineVariant.opacity(0.35))
                .frame(height: 1)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(UtilityTool.allCases) { tool in
                        toolRow(tool)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, DesignTokens.Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.Colors.surfaceLowest.opacity(0.92))
    }

    private var detail: some View {
        ScrollView {
            utilityDetail(selectedTool)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.vertical, DesignTokens.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.automatic)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppCanvasBackground())
    }

    private func toolRow(_ tool: UtilityTool) -> some View {
        let isSelected = selectedTool == tool

        return Button {
            selectedTool = tool
        } label: {
            Label(tool.title, systemImage: tool.symbolName)
                .font(DesignTokens.Typography.secondary.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(
                    isSelected ? DesignTokens.Colors.onSurface : DesignTokens.Colors.onSurfaceVariant
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
                        .fill(isSelected ? DesignTokens.Colors.primaryContainer.opacity(0.20) : .clear)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
                        .strokeBorder(
                            isSelected ? DesignTokens.Colors.primary.opacity(0.35) : .clear,
                            lineWidth: 1
                        )
                }
                .contentShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(tool.subtitle)
    }

    private func applyPendingUtility() {
        if let pending = navigation.pendingUtilityTool {
            selectedTool = pending
            navigation.pendingUtilityTool = nil
        }
    }

    @ViewBuilder
    private func utilityDetail(_ tool: UtilityTool) -> some View {
        switch tool {
        case .uuid: UUIDGeneratorToolView()
        case .jwt: JWTDecoderToolView()
        case .base64: Base64ToolView()
        case .jsonFormat: JSONFormatterToolView()
        case .jsonCompare: JSONCompareToolView()
        case .regex: RegexTesterToolView()
        case .cron: CronParserToolView()
        case .timestamp: TimestampToolView()
        case .hash: HashGeneratorToolView()
        case .qr: QRGeneratorToolView()
        case .color: ColorPickerToolView()
        }
    }
}
