import SwiftUI

/// Primary navigation shell.
struct RootView: View {
    private let environment: AppEnvironment
    @Bindable private var navigation: AppNavigationStore

    init(environment: AppEnvironment) {
        self.environment = environment
        self.navigation = environment.navigationStore
    }

    var body: some View {
        ZStack {
            DesignTokens.Colors.background.ignoresSafeArea()

            NavigationSplitView {
                sidebar
            } detail: {
                detailView
            }
            .navigationSplitViewStyle(.balanced)

            if navigation.isCommandPalettePresented {
                Color.primary.opacity(0.28)
                    .ignoresSafeArea()
                    .onTapGesture { navigation.closeCommandPalette() }

                CommandPaletteView(
                    items: commandItems,
                    onSelect: handleCommand,
                    onDismiss: { navigation.closeCommandPalette() }
                )
                .transition(.scale(scale: 0.98).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .animation(DesignTokens.Motion.panel, value: navigation.isCommandPalettePresented)
        .preferredColorScheme(environment.settingsStore.appearance.colorScheme)
        .tint(environment.settingsStore.accentColor.color ?? DesignTokens.Colors.primaryContainer)
        .toolbar {
            ToolbarItem(placement: .principal) {
                CommandSearchBar(
                    phrases: searchPhrases,
                    onActivate: { navigation.openCommandPalette() }
                )
                .keyboardShortcut("k", modifiers: .command)
            }
        }
    }

    private var searchPhrases: [String] {
        let titles = environment.featureRegistry.modules.map(\.title)
        return titles.isEmpty ? CommandSearchBar.defaultPhrases : titles
    }

    private var sidebar: some View {
        List(selection: $navigation.selectedFeatureID) {
            ForEach(AppSidebarSection.allCases) { section in
                let modules = environment.featureRegistry.modules.filter {
                    AppSidebarSection.section(for: $0.id) == section
                }
                if !modules.isEmpty {
                    Section {
                        ForEach(modules, id: \.id) { module in
                            Label(module.title, systemImage: module.symbolName)
                                .tag(module.id)
                                .accessibilityLabel(module.title)
                        }
                    } header: {
                        Text(section.title.uppercased())
                            .font(DesignTokens.Typography.labelCaps)
                            .tracking(0.8)
                            .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Colors.surfaceLowest.opacity(0.92))
        .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 280)
        .safeAreaInset(edge: .top) {
            sidebarBrand
        }
        .safeAreaInset(edge: .bottom) {
            sidebarFooter
        }
    }

    private var sidebarBrand: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.icon, style: .continuous)
                    .fill(DesignTokens.Colors.primaryContainer)
                Text("D")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("DAD")
                    .font(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Colors.primary)
                Text("Dev Action Dashboard")
                    .font(DesignTokens.Typography.monoCaption)
                    .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surfaceLowest.opacity(0.95))
    }

    private var sidebarFooter: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Button {
                Task { await environment.systemActionService.perform(.openTerminal) }
            } label: {
                Label("Open Terminal", systemImage: "terminal")
                    .font(DesignTokens.Typography.caption)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(DesignTokens.Colors.primary)

            HStack {
                compactMeter(
                    title: "CPU",
                    value: environment.systemMetricsService.latest.map {
                        MetricsFormatter.percent($0.cpu.usageRatio)
                    } ?? "—"
                )
                Spacer()
                compactMeter(
                    title: "MEM",
                    value: environment.systemMetricsService.latest.map {
                        MetricsFormatter.percent($0.memory.usageRatio)
                    } ?? "—"
                )
            }

            Text("⌘K Command Palette")
                .font(DesignTokens.Typography.monoCaption)
                .foregroundStyle(DesignTokens.Colors.onSurfaceVariant.opacity(0.6))
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surfaceLowest.opacity(0.95))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(DesignTokens.Colors.outlineVariant.opacity(0.35))
                .frame(height: 1)
        }
        .onAppear {
            environment.systemMetricsService.startMonitoring()
        }
    }

    private func compactMeter(title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(DesignTokens.Typography.monoCaption)
                .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
            Text(value)
                .font(DesignTokens.Typography.monoCaption)
                .foregroundStyle(DesignTokens.Colors.onSurface)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private var detailView: some View {
        if let selectedFeatureID = navigation.selectedFeatureID,
           let module = environment.featureRegistry.module(for: selectedFeatureID) {
            module.makeRootView()
                .navigationTitle(module.title)
        } else {
            ContentUnavailableView(
                "Select a feature",
                systemImage: "sidebar.left",
                description: Text("Choose an item from the sidebar or press ⌘K.")
            )
            .foregroundStyle(DesignTokens.Colors.onSurface)
            .background(AppCanvasBackground())
        }
    }

    private var commandItems: [CommandPaletteItem] {
        CommandPaletteItem.features(from: environment.featureRegistry)
            + CommandPaletteItem.utilities
            + CommandPaletteItem.actions
    }

    private func handleCommand(_ item: CommandPaletteItem) {
        switch item.kind {
        case .feature(let id):
            navigation.navigate(to: id)
        case .utility(let tool):
            navigation.openUtility(tool)
        case .action:
            navigation.openActions()
        }
    }
}
