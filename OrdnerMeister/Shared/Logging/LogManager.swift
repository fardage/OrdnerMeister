//
//  LogManager.swift
//  OrdnerMeister
//
//  Created by Claude Code
//

import Foundation
import OrdnerMeisterDomain
import OSLog

/// Manages file-based logging for OrdnerMeister
/// Thread-safe singleton that writes structured logs to disk
public actor LogManager {
    public static let shared = LogManager()

    private let fileManager = FileManager.default
    private let maxLogAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    private let maxLogFileSize: Int64 = 50 * 1024 * 1024 // 50 MB

    /// Directory where log files are stored
    public var logDirectoryURL: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("OrdnerMeister")
            .appendingPathComponent("logs")
    }

    private init() {}

    /// Set up the log manager (creates log directory if needed)
    public func setup() throws {
        try fileManager.createDirectory(
            at: logDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // Clean old logs on setup
        try? cleanOldLogs()
    }

    /// Write a log entry to the current log file
    public func writeLog(_ entry: LogEntry) async throws {
        let logFileURL = try getCurrentLogFileURL()
        let formattedEntry = entry.formatted() + "\n"

        // Check if file needs rotation
        if shouldRotateLogFile(logFileURL) {
            try rotateLogFile()
        }

        // Append to log file
        if fileManager.fileExists(atPath: logFileURL.path) {
            let fileHandle = try FileHandle(forWritingTo: logFileURL)
            try fileHandle.seekToEnd()
            try fileHandle.write(contentsOf: Data(formattedEntry.utf8))
            try fileHandle.close()
        } else {
            try formattedEntry.write(to: logFileURL, atomically: true, encoding: .utf8)
        }
    }

    /// Get the current log file URL (based on today's date)
    public func getCurrentLogFileURL() throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())

        return logDirectoryURL.appendingPathComponent("ordnermeister-\(dateString).log")
    }

    /// Get URL to the log directory for opening in Finder/Console
    public func getLogDirectoryURL() -> URL {
        logDirectoryURL
    }

    /// Clean up log files older than maxLogAge
    public func cleanOldLogs() throws {
        let logFiles = try fileManager.contentsOfDirectory(
            at: logDirectoryURL,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )

        let now = Date()

        for logFile in logFiles where logFile.pathExtension == "log" {
            let attributes = try fileManager.attributesOfItem(atPath: logFile.path)
            if let creationDate = attributes[.creationDate] as? Date {
                let age = now.timeIntervalSince(creationDate)
                if age > maxLogAge {
                    try fileManager.removeItem(at: logFile)
                    Logger.general.info("Removed old log file: \(logFile.lastPathComponent)")
                }
            }
        }
    }

    // MARK: - Private Helpers

    private func shouldRotateLogFile(_ fileURL: URL) -> Bool {
        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let fileSize = attributes[.size] as? Int64 else {
            return false
        }

        return fileSize > maxLogFileSize
    }

    private func rotateLogFile() throws {
        let currentLogURL = try getCurrentLogFileURL()

        guard fileManager.fileExists(atPath: currentLogURL.path) else {
            return
        }

        // Create rotated file name with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let timestamp = dateFormatter.string(from: Date())

        let rotatedURL = logDirectoryURL.appendingPathComponent("ordnermeister-\(timestamp).log")

        try fileManager.moveItem(at: currentLogURL, to: rotatedURL)
        Logger.general.info("Rotated log file to: \(rotatedURL.lastPathComponent)")
    }
}

// MARK: - Convenience Logging Extensions

extension LogManager {
    /// Log an info message
    public func info(
        category: String,
        message: String,
        context: [String: String]? = nil
    ) async {
        let entry = LogEntry(level: .info, category: category, message: message, context: context)
        try? await writeLog(entry)
    }

    /// Log a warning message
    public func warning(
        category: String,
        message: String,
        context: [String: String]? = nil
    ) async {
        let entry = LogEntry(level: .warning, category: category, message: message, context: context)
        try? await writeLog(entry)
    }

    /// Log an error message
    public func error(
        category: String,
        message: String,
        context: [String: String]? = nil
    ) async {
        let entry = LogEntry(level: .error, category: category, message: message, context: context)
        try? await writeLog(entry)
    }

    /// Log a debug message
    public func debug(
        category: String,
        message: String,
        context: [String: String]? = nil
    ) async {
        let entry = LogEntry(level: .debug, category: category, message: message, context: context)
        try? await writeLog(entry)
    }
}
