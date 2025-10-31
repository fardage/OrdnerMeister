import Foundation

/// Structured log entry for file-based logging
public struct LogEntry: Sendable, Codable {
    /// Timestamp when the log entry was created
    public let timestamp: Date

    /// Log level
    public let level: LogLevel

    /// Log category (e.g., "OCR", "Classifier", "FileSystem")
    public let category: String

    /// Log message
    public let message: String

    /// Optional context data (file paths, operation IDs, etc.)
    public let context: [String: String]?

    public init(
        timestamp: Date = Date(),
        level: LogLevel,
        category: String,
        message: String,
        context: [String: String]? = nil
    ) {
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
        self.context = context
    }

    /// Format log entry as a string for file output
    public func formatted() -> String {
        let dateFormatter = ISO8601DateFormatter()
        let timestampString = dateFormatter.string(from: timestamp)

        var output = "[\(timestampString)] [\(level.rawValue.uppercased())] [\(category)] \(message)"

        if let context = context, !context.isEmpty {
            let contextString = context
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: ", ")
            output += " | \(contextString)"
        }

        return output
    }

    /// Log level enumeration
    public enum LogLevel: String, Codable, Sendable {
        case trace
        case debug
        case info
        case warning
        case error
        case critical
    }
}
