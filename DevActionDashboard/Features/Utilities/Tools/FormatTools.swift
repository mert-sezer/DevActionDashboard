import SwiftUI

struct UUIDGeneratorToolView: View {
    @State private var uppercase = true
    @State private var value = DeveloperUtilityEngine.generateUUID(uppercase: true)

    var body: some View {
        UtilityToolChrome(tool: .uuid) {
            GlassPanel {
                Toggle("Uppercase", isOn: $uppercase)
                    .onChange(of: uppercase) { _, newValue in
                        value = DeveloperUtilityEngine.generateUUID(uppercase: newValue)
                    }

                UtilityOutputWell(text: value, minHeight: 52, accessibilityLabel: "Generated UUID")

                HStack(spacing: DesignTokens.Spacing.sm) {
                    Button("Generate") {
                        value = DeveloperUtilityEngine.generateUUID(uppercase: uppercase)
                    }
                    .buttonStyle(UtilityProminentButtonStyle())
                    Button("Copy") { UtilityClipboard.copy(value) }
                        .buttonStyle(UtilitySecondaryButtonStyle())
                }
            }
        }
    }
}

struct Base64ToolView: View {
    @State private var input = ""
    @State private var output = ""
    @State private var errorMessage: String?

    var body: some View {
        UtilityToolChrome(tool: .base64) {
            GlassPanel {
                UtilityCodeEditor(text: $input, minHeight: 140)

                HStack(spacing: DesignTokens.Spacing.sm) {
                    Button("Encode") {
                        output = DeveloperUtilityEngine.base64Encode(input)
                        errorMessage = nil
                    }
                    .buttonStyle(UtilityProminentButtonStyle())
                    Button("Decode") {
                        switch DeveloperUtilityEngine.base64Decode(input) {
                        case .success(let value):
                            output = value
                            errorMessage = nil
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                        }
                    }
                    .buttonStyle(UtilitySecondaryButtonStyle())
                    Button("Copy Output") { UtilityClipboard.copy(output) }
                        .buttonStyle(UtilitySecondaryButtonStyle())
                        .disabled(output.isEmpty)
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(DesignTokens.Colors.error)
                }

                UtilityOutputWell(text: output, minHeight: 88, accessibilityLabel: "Base64 output")
            }
        }
    }
}

struct JSONFormatterToolView: View {
    @State private var input = "{\n  \"hello\": \"world\"\n}"
    @State private var output = ""
    @State private var errorMessage: String?

    var body: some View {
        UtilityToolChrome(tool: .jsonFormat) {
            GlassPanel {
                UtilityCodeEditor(text: $input, minHeight: 200)

                HStack(spacing: DesignTokens.Spacing.sm) {
                    Button("Format") {
                        switch DeveloperUtilityEngine.formatJSON(input) {
                        case .success(let value):
                            output = value
                            errorMessage = nil
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                        }
                    }
                    .buttonStyle(UtilityProminentButtonStyle())
                    Button("Copy") { UtilityClipboard.copy(output.isEmpty ? input : output) }
                        .buttonStyle(UtilitySecondaryButtonStyle())
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(DesignTokens.Colors.error)
                }

                if !output.isEmpty {
                    UtilityOutputWell(text: output, minHeight: 140, accessibilityLabel: "Formatted JSON")
                }
            }
        }
    }
}

struct JSONCompareToolView: View {
    @State private var left = "{\"a\":1}"
    @State private var right = "{\"a\":1}"
    @State private var resultText = ""
    @State private var errorMessage: String?

    var body: some View {
        UtilityToolChrome(tool: .jsonCompare) {
            GlassPanel {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                    UtilityCodeEditor(text: $left, minHeight: 160)
                    UtilityCodeEditor(text: $right, minHeight: 160)
                }

                Button("Compare") {
                    switch DeveloperUtilityEngine.compareJSON(left: left, right: right) {
                    case .success(let result):
                        resultText = result.areEqual
                            ? "Equal"
                            : "Different\n\nLeft:\n\(result.leftCanonical)\n\nRight:\n\(result.rightCanonical)"
                        errorMessage = nil
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
                .buttonStyle(UtilityProminentButtonStyle())

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(DesignTokens.Colors.error)
                }

                if !resultText.isEmpty {
                    UtilityOutputWell(text: resultText, minHeight: 88, accessibilityLabel: "Compare result")
                }
            }
        }
    }
}
