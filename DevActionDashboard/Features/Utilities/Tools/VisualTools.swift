import AppKit
import SwiftUI

struct QRGeneratorToolView: View {
    @State private var input = "https://github.com"
    @State private var image: NSImage?

    var body: some View {
        UtilityToolChrome(tool: .qr) {
            GlassPanel {
                TextField("Content", text: $input)
                    .textFieldStyle(.roundedBorder)

                Button("Generate") {
                    image = QRCodeGenerator.image(from: input)
                }
                .buttonStyle(UtilityProminentButtonStyle())

                if let image {
                    Image(nsImage: image)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 220, height: 220)
                        .accessibilityLabel("Generated QR code")
                } else {
                    Text("Enter text and generate a QR code.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct ColorPickerToolView: View {
    @State private var color = Color.accentColor
    @State private var hex = "#007AFF"

    var body: some View {
        UtilityToolChrome(tool: .color) {
            GlassPanel {
                ColorPicker("Color", selection: $color, supportsOpacity: true)
                    .onChange(of: color) { _, newValue in
                        hex = Self.hexString(from: newValue)
                    }

                UtilityOutputWell(text: hex, minHeight: 44, accessibilityLabel: "Hex color")

                Button("Copy Hex") { UtilityClipboard.copy(hex) }
                    .buttonStyle(UtilitySecondaryButtonStyle())
            }
            .onAppear {
                hex = Self.hexString(from: color)
            }
        }
    }

    private static func hexString(from color: Color) -> String {
        let nsColor = NSColor(color)
        guard let converted = nsColor.usingColorSpace(.sRGB) else {
            return "#000000"
        }
        let r = Int((converted.redComponent * 255).rounded())
        let g = Int((converted.greenComponent * 255).rounded())
        let b = Int((converted.blueComponent * 255).rounded())
        let a = Int((converted.alphaComponent * 255).rounded())
        if a < 255 {
            return String(format: "#%02X%02X%02X%02X", r, g, b, a)
        }
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
