import SwiftUI

struct AboutView: View {
    private let version: String
    private let build: String

    init(bundle: Bundle = .main) {
        version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
        build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    var body: some View {
        FeaturePage(
            title: "About",
            subtitle: "Dev Action Dashboard — the developer action center for macOS."
        ) {
            GlassPanel {
                Text("Dev Action Dashboard")
                    .font(DesignTokens.Typography.title)
                    .accessibilityAddTraits(.isHeader)

                MetadataRow(label: "Short name", value: "DAD")
                MetadataRow(label: "Version", value: version, monospaced: true)
                MetadataRow(label: "Build", value: build, monospaced: true)
                MetadataRow(label: "License", value: "MIT")
            }

            GlassPanel {
                Text("Mission")
                    .font(DesignTokens.Typography.title)
                    .accessibilityAddTraits(.isHeader)

                Text("Centralize developer tools, system insight, and local productivity into one native macOS application — fast, accessible, and maintainable.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    AboutView()
        .frame(width: 720, height: 480)
}
