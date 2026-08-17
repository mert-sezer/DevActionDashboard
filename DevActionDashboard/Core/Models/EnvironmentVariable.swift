import Foundation

/// A single process environment variable.
public struct EnvironmentVariable: Identifiable, Sendable, Equatable, Hashable {
    public var id: String { key }

    public let key: String
    public let value: String

    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

public struct EnvironmentVariableSnapshot: Sendable, Equatable {
    public let timestamp: Date
    public let variables: [EnvironmentVariable]

    public init(timestamp: Date = .now, variables: [EnvironmentVariable]) {
        self.timestamp = timestamp
        self.variables = variables
    }
}

public struct EnvironmentVariableComparison: Sendable, Equatable {
    public let leftKey: String
    public let rightKey: String
    public let leftValue: String
    public let rightValue: String
    public let areEqual: Bool
    public let leftOnlyLines: [String]
    public let rightOnlyLines: [String]
    public let sharedLines: [String]

    public init(
        leftKey: String,
        rightKey: String,
        leftValue: String,
        rightValue: String
    ) {
        self.leftKey = leftKey
        self.rightKey = rightKey
        self.leftValue = leftValue
        self.rightValue = rightValue
        self.areEqual = leftValue == rightValue

        let leftSet = Set(leftValue.split(whereSeparator: \.isNewline).map(String.init))
        let rightSet = Set(rightValue.split(whereSeparator: \.isNewline).map(String.init))
        self.leftOnlyLines = leftSet.subtracting(rightSet).sorted()
        self.rightOnlyLines = rightSet.subtracting(leftSet).sorted()
        self.sharedLines = leftSet.intersection(rightSet).sorted()
    }
}
