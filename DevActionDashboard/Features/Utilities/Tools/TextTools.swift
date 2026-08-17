import SwiftUI

struct JWTDecoderToolView: View {
    @State private var token = ""
    @State private var header = ""
    @State private var payload = ""
    @State private var errorMessage: String?

    var body: some View {
        UtilityToolChrome(tool: .jwt) {
            GlassPanel {
                UtilityCodeEditor(text: $token, minHeight: 120)

                Button("Decode") {
                    switch DeveloperUtilityEngine.decodeJWT(token) {
                    case .success(let result):
                        header = result.headerJSON
                        payload = result.payloadJSON
                        errorMessage = result.signaturePresent ? nil : "Token has no signature segment."
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
                .buttonStyle(UtilityProminentButtonStyle())

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(DesignTokens.Colors.error)
                }

                if !header.isEmpty {
                    labeledOutput("Header", header)
                }
                if !payload.isEmpty {
                    labeledOutput("Payload", payload)
                }
            }
        }
    }

    private func labeledOutput(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(title)
                .font(DesignTokens.Typography.secondary.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.onSurfaceVariant)
            UtilityOutputWell(text: value, minHeight: 72, accessibilityLabel: title)
        }
    }
}

struct RegexTesterToolView: View {
    @State private var pattern = #"(\w+)"#
    @State private var text = "hello world"
    @State private var result = ""
    @State private var errorMessage: String?

    var body: some View {
        UtilityToolChrome(tool: .regex) {
            GlassPanel {
                TextField("Pattern", text: $pattern)
                    .textFieldStyle(.roundedBorder)
                    .font(DesignTokens.Typography.mono)

                UtilityCodeEditor(text: $text, minHeight: 120)

                Button("Test") {
                    switch DeveloperUtilityEngine.testRegex(pattern: pattern, text: text) {
                    case .success(let value):
                        if value.matches.isEmpty {
                            result = "No matches"
                        } else {
                            result = value.matches.enumerated().map { index, match in
                                "Match \(index + 1): \(match.value) · groups=\(match.groups)"
                            }.joined(separator: "\n")
                        }
                        errorMessage = nil
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
                .buttonStyle(UtilityProminentButtonStyle())

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(DesignTokens.Colors.error)
                }

                if !result.isEmpty {
                    UtilityOutputWell(text: result, minHeight: 88, accessibilityLabel: "Regex matches")
                }
            }
        }
    }
}

struct CronParserToolView: View {
    @State private var expression = "*/5 * * * *"
    @State private var descriptionText = ""
    @State private var errorMessage: String?

    var body: some View {
        UtilityToolChrome(tool: .cron) {
            GlassPanel {
                TextField("Expression", text: $expression)
                    .textFieldStyle(.roundedBorder)
                    .font(DesignTokens.Typography.mono)

                Button("Parse") {
                    switch DeveloperUtilityEngine.describeCron(expression) {
                    case .success(let value):
                        descriptionText = value
                        errorMessage = nil
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
                .buttonStyle(UtilityProminentButtonStyle())

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(DesignTokens.Colors.error)
                }

                if !descriptionText.isEmpty {
                    UtilityOutputWell(
                        text: descriptionText,
                        minHeight: 64,
                        accessibilityLabel: "Cron description"
                    )
                }
            }
        }
    }
}

struct TimestampToolView: View {
    @State private var input = ""
    @State private var output = ""
    @State private var errorMessage: String?

    var body: some View {
        UtilityToolChrome(tool: .timestamp) {
            GlassPanel {
                TextField("Input (unix / ISO-8601 / empty for now)", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .font(DesignTokens.Typography.mono)

                Button("Convert") {
                    switch DeveloperUtilityEngine.convertTimestamp(input) {
                    case .success(let value):
                        let iso = ISO8601DateFormatter().string(from: value.date)
                        output = """
                        ISO-8601: \(iso)
                        Unix seconds: \(Int(value.unixSeconds))
                        Unix millis: \(Int(value.unixMilliseconds))
                        """
                        errorMessage = nil
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
                .buttonStyle(UtilityProminentButtonStyle())

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(DesignTokens.Colors.error)
                }

                if !output.isEmpty {
                    UtilityOutputWell(text: output, minHeight: 88, accessibilityLabel: "Converted timestamp")
                }
            }
        }
    }
}

struct HashGeneratorToolView: View {
    @State private var input = ""
    @State private var algorithm: HashAlgorithm = .sha256
    @State private var output = ""

    var body: some View {
        UtilityToolChrome(tool: .hash) {
            GlassPanel {
                UtilityCodeEditor(text: $input, minHeight: 120)

                Picker("Algorithm", selection: $algorithm) {
                    ForEach(HashAlgorithm.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                HStack(spacing: DesignTokens.Spacing.sm) {
                    Button("Hash") {
                        output = DeveloperUtilityEngine.hash(input, algorithm: algorithm)
                    }
                    .buttonStyle(UtilityProminentButtonStyle())
                    Button("Copy") { UtilityClipboard.copy(output) }
                        .buttonStyle(UtilitySecondaryButtonStyle())
                        .disabled(output.isEmpty)
                }

                if !output.isEmpty {
                    UtilityOutputWell(text: output, minHeight: 52, accessibilityLabel: "Hash digest")
                }
            }
        }
    }
}
