import AppKit
import SwiftUI

/// Adaptive color, spacing, radius, and typography tokens.
public enum DesignTokens {
    public enum Colors {
        // Surfaces
        public static let background = dynamic(
            light: srgb(0xF5, 0xFA, 0xFA),
            dark: srgb(0x05, 0x14, 0x24)
        )
        public static let surfaceLowest = dynamic(
            light: srgb(0xFF, 0xFF, 0xFF),
            dark: srgb(0x01, 0x0F, 0x1F)
        )
        public static let surfaceLow = dynamic(
            light: srgb(0xEF, 0xF5, 0xF4),
            dark: srgb(0x0D, 0x1C, 0x2D)
        )
        public static let surface = dynamic(
            light: srgb(0xEA, 0xEF, 0xEE),
            dark: srgb(0x12, 0x21, 0x31)
        )
        public static let surfaceHigh = dynamic(
            light: srgb(0xE4, 0xE9, 0xE8),
            dark: srgb(0x1C, 0x2B, 0x3C)
        )
        public static let surfaceHighest = dynamic(
            light: srgb(0xDE, 0xE4, 0xE3),
            dark: srgb(0x27, 0x36, 0x47)
        )
        /// Elevated cards / panels (white in light, high surface in dark).
        public static let card = dynamic(
            light: srgb(0xFF, 0xFF, 0xFF),
            dark: srgb(0x1C, 0x2B, 0x3C)
        )

        public static let onSurface = dynamic(
            light: srgb(0x17, 0x1D, 0x1C),
            dark: srgb(0xD4, 0xE4, 0xFA)
        )
        public static let onSurfaceVariant = dynamic(
            light: srgb(0x3D, 0x49, 0x49),
            dark: srgb(0xBC, 0xC9, 0xC8)
        )
        public static let outline = dynamic(
            light: srgb(0x6D, 0x7A, 0x79),
            dark: srgb(0x86, 0x93, 0x93)
        )
        public static let outlineVariant = dynamic(
            light: srgb(0xBC, 0xC9, 0xC8),
            dark: srgb(0x3D, 0x49, 0x49)
        )

        /// Readable accent for text/icons (darker teal in light, bright in dark).
        public static let primary = dynamic(
            light: srgb(0x00, 0x6A, 0x6A),
            dark: srgb(0x60, 0xD8, 0xD8)
        )
        public static let primaryContainer = Color(red: 0.149, green: 0.678, blue: 0.678) // #26ADAD
        public static let onPrimary = dynamic(
            light: .white,
            dark: srgb(0x00, 0x3B, 0x3B)
        )
        public static let onPrimaryContainer = Color(red: 0.0, green: 0.231, blue: 0.231) // #003b3b
        public static let tertiary = dynamic(
            light: srgb(0x95, 0x49, 0x1D),
            dark: srgb(0xFF, 0xB6, 0x91)
        )
        public static let error = dynamic(
            light: srgb(0xBA, 0x1A, 0x1A),
            dark: srgb(0xFF, 0xB4, 0xAB)
        )

        public static let hairline = dynamic(
            light: NSColor.black.withAlphaComponent(0.08),
            dark: NSColor.white.withAlphaComponent(0.10)
        )

        // MARK: - Dynamic helpers

        private static func dynamic(light: NSColor, dark: NSColor) -> Color {
            Color(
                nsColor: NSColor(name: nil, dynamicProvider: { appearance in
                    appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
                })
            )
        }

        private static func srgb(_ r: Int, _ g: Int, _ b: Int, alpha: CGFloat = 1) -> NSColor {
            NSColor(
                srgbRed: CGFloat(r) / 255,
                green: CGFloat(g) / 255,
                blue: CGFloat(b) / 255,
                alpha: alpha
            )
        }
    }

    public enum Spacing {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let sm: CGFloat = 12
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 40
        public static let sidebarWidth: CGFloat = 240
        public static let gutter: CGFloat = 16
    }

    public enum Radius {
        public static let control: CGFloat = 8
        public static let selection: CGFloat = 4
        public static let panel: CGFloat = 12
        public static let card: CGFloat = 8
        public static let sheet: CGFloat = 16
        public static let icon: CGFloat = 10
    }

    public enum Typography {
        public static let brand = Font.system(size: 13, weight: .bold, design: .rounded)
        public static let hero = Font.system(size: 24, weight: .semibold, design: .default)
        public static let title = Font.system(size: 18, weight: .semibold, design: .default)
        public static let body = Font.system(size: 14, weight: .regular, design: .default)
        public static let secondary = Font.system(size: 13, weight: .regular, design: .default)
        public static let caption = Font.system(size: 12, weight: .regular, design: .default)
        public static let labelCaps = Font.system(size: 11, weight: .bold, design: .default)
        public static let mono = Font.system(size: 13, weight: .regular, design: .monospaced)
        public static let monoCaption = Font.system(size: 11, weight: .medium, design: .monospaced)
        public static let metric = Font.system(size: 28, weight: .medium, design: .monospaced)
        public static let metricUnit = Font.system(size: 16, weight: .medium, design: .monospaced)
    }

    public enum Motion {
        public static let quick = Animation.easeInOut(duration: 0.18)
        public static let panel = Animation.spring(response: 0.32, dampingFraction: 0.86)
        public static let welcome = Animation.easeOut(duration: 0.8)
    }
}

/// User-selectable accent used across chrome and charts.
public enum AppAccentColor: String, CaseIterable, Identifiable, Sendable {
    case system
    case blue
    case teal
    case indigo
    case orange

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .system: "System"
        case .blue: "Blue"
        case .teal: "Teal"
        case .indigo: "Indigo"
        case .orange: "Orange"
        }
    }

    public var color: Color? {
        switch self {
        case .system: nil
        case .blue: Color(red: 0.20, green: 0.48, blue: 0.96)
        case .teal: DesignTokens.Colors.primaryContainer
        case .indigo: Color(red: 0.35, green: 0.40, blue: 0.85)
        case .orange: DesignTokens.Colors.tertiary
        }
    }
}
