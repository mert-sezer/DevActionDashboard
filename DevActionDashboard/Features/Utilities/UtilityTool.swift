import Foundation

public enum UtilityTool: String, CaseIterable, Identifiable, Sendable, Hashable {
    case uuid
    case jwt
    case base64
    case jsonFormat
    case jsonCompare
    case regex
    case cron
    case timestamp
    case hash
    case qr
    case color

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .uuid: "UUID Generator"
        case .jwt: "JWT Decoder"
        case .base64: "Base64"
        case .jsonFormat: "JSON Formatter"
        case .jsonCompare: "JSON Compare"
        case .regex: "Regex Tester"
        case .cron: "Cron Parser"
        case .timestamp: "Timestamp"
        case .hash: "Hash Generator"
        case .qr: "QR Generator"
        case .color: "Color Picker"
        }
    }

    public var symbolName: String {
        switch self {
        case .uuid: "number.square"
        case .jwt: "lock.rectangle"
        case .base64: "textformat.abc"
        case .jsonFormat: "curlybraces"
        case .jsonCompare: "arrow.left.arrow.right"
        case .regex: "text.magnifyingglass"
        case .cron: "calendar.badge.clock"
        case .timestamp: "clock"
        case .hash: "number"
        case .qr: "qrcode"
        case .color: "paintpalette"
        }
    }

    public var subtitle: String {
        switch self {
        case .uuid: "Generate RFC 4122 UUIDs."
        case .jwt: "Decode header and payload. Signature is not verified."
        case .base64: "Encode and decode UTF-8 text."
        case .jsonFormat: "Pretty-print and sort object keys."
        case .jsonCompare: "Canonicalize both sides and compare equality."
        case .regex: "Evaluate NSRegularExpression matches."
        case .cron: "Describe standard 5/6-field cron expressions."
        case .timestamp: "Unix seconds/millis or ISO-8601 ↔ Date."
        case .hash: "CryptoKit digests for UTF-8 input."
        case .qr: "Create a QR code with Core Image."
        case .color: "Pick a color and copy its sRGB hex value."
        }
    }
}
