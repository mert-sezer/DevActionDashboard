import Foundation

/// Minimal cron (5-field) descriptor for developer tooling.
enum CronExpressionParser {
    static func describe(_ expression: String) -> Result<String, UtilityTransformError> {
        let fields = expression
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
        guard fields.count == 5 || fields.count == 6 else {
            return .failure(.invalidCron("Expected 5 or 6 fields"))
        }

        let offset = fields.count == 6 ? 1 : 0
        let minute = fields[offset]
        let hour = fields[offset + 1]
        let dayOfMonth = fields[offset + 2]
        let month = fields[offset + 3]
        let dayOfWeek = fields[offset + 4]

        let parts = [
            "minute \(describeField(minute, unit: "minute", range: 0...59))",
            "hour \(describeField(hour, unit: "hour", range: 0...23))",
            "day-of-month \(describeField(dayOfMonth, unit: "day", range: 1...31))",
            "month \(describeField(month, unit: "month", range: 1...12))",
            "day-of-week \(describeField(dayOfWeek, unit: "weekday", range: 0...7))"
        ]

        return .success(parts.joined(separator: "; "))
    }

    private static func describeField(_ field: String, unit: String, range: ClosedRange<Int>) -> String {
        if field == "*" { return "every \(unit)" }
        if field == "?" { return "any \(unit)" }
        if field.hasPrefix("*/"), let step = Int(field.dropFirst(2)), step > 0 {
            return "every \(step) \(unit)s"
        }
        if field.contains("-"), field.split(separator: "-").count == 2 {
            let bounds = field.split(separator: "-")
            if let start = Int(bounds[0]), let end = Int(bounds[1]), range.contains(start), range.contains(end) {
                return "from \(start) through \(end)"
            }
        }
        if field.contains(",") {
            return "at \(field)"
        }
        if let value = Int(field), range.contains(value) || (unit == "weekday" && value == 7) {
            return "at \(value)"
        }
        return "‘\(field)’"
    }
}
