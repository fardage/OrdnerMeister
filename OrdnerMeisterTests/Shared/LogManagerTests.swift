import Testing
import Foundation
@testable import OrdnerMeister
import OrdnerMeisterDomain

/// Tests for LogManager
@Suite("LogManager Tests")
struct LogManagerTests {

    @Test("LogManager creates log directory on setup")
    func testSetup() async throws {
        let manager = LogManager.shared

        // Setup creates the logs directory
        try await manager.setup()

        let logDirectory = manager.logDirectoryURL
        let fileManager = FileManager.default

        // Verify directory exists
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: logDirectory.path, isDirectory: &isDirectory)

        #expect(exists)
        #expect(isDirectory.boolValue)
    }

    @Test("LogManager writes log entries to file")
    func testWriteLog() async throws {
        let manager = LogManager.shared
        try await manager.setup()

        let logEntry = LogEntry(
            level: .info,
            category: "Test",
            message: "Test log message",
            context: ["key": "value"]
        )

        // Write log entry
        try await manager.writeLog(logEntry)

        // Read log file and verify entry exists
        let logFileURL = try manager.getCurrentLogFileURL()
        let logContent = try String(contentsOf: logFileURL, encoding: .utf8)

        #expect(logContent.contains("Test log message"))
        #expect(logContent.contains("INFO"))
        #expect(logContent.contains("Test"))
    }

    @Test("LogManager formats log entries correctly")
    func testLogEntryFormatting() {
        let logEntry = LogEntry(
            timestamp: Date(timeIntervalSince1970: 1609459200), // 2021-01-01 00:00:00 UTC
            level: .error,
            category: "TestCategory",
            message: "Test error message",
            context: ["file": "test.pdf", "operation": "read"]
        )

        let formatted = logEntry.formatted()

        #expect(formatted.contains("ERROR"))
        #expect(formatted.contains("TestCategory"))
        #expect(formatted.contains("Test error message"))
        #expect(formatted.contains("file=test.pdf"))
        #expect(formatted.contains("operation=read"))
    }

    @Test("LogManager is thread-safe")
    func testThreadSafety() async throws {
        let manager = LogManager.shared
        try await manager.setup()

        // Write multiple log entries concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 1...50 {
                group.addTask {
                    let entry = LogEntry(
                        level: .info,
                        category: "ConcurrencyTest",
                        message: "Message \(i)"
                    )
                    try? await manager.writeLog(entry)
                }
            }
        }

        // Verify log file exists and has content
        let logFileURL = try manager.getCurrentLogFileURL()
        let logContent = try String(contentsOf: logFileURL, encoding: .utf8)

        #expect(!logContent.isEmpty)
        #expect(logContent.contains("ConcurrencyTest"))
    }

    @Test("LogManager creates daily log files")
    func testDailyLogFiles() async throws {
        let manager = LogManager.shared
        try await manager.setup()

        let logFileURL = try manager.getCurrentLogFileURL()
        let fileName = logFileURL.lastPathComponent

        // Verify file name contains date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())

        #expect(fileName.contains(todayString))
        #expect(fileName.hasSuffix(".log"))
    }

    @Test("LogManager cleans old log files")
    func testLogCleanup() async throws {
        let manager = LogManager.shared
        try await manager.setup()

        let fileManager = FileManager.default
        let logDirectory = manager.logDirectoryURL

        // Create some old log files
        let calendar = Calendar.current
        for daysAgo in 1...10 {
            if let oldDate = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateString = dateFormatter.string(from: oldDate)

                let oldLogFile = logDirectory.appendingPathComponent("ordnermeister-\(dateString).log")
                try "Old log content".write(to: oldLogFile, atomically: true, encoding: .utf8)
            }
        }

        // Clean logs (should keep last 7 days)
        try await manager.cleanOldLogs()

        // Count remaining log files
        let logFiles = try fileManager.contentsOfDirectory(at: logDirectory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "log" }

        // Should have at most 7 old logs + today's log
        #expect(logFiles.count <= 8)
    }

    @Test("LogManager handles write errors gracefully")
    func testWriteErrorHandling() async throws {
        let manager = LogManager.shared
        try await manager.setup()

        // Create a log entry
        let logEntry = LogEntry(
            level: .warning,
            category: "ErrorTest",
            message: "This should be written successfully"
        )

        // This should not throw
        try await manager.writeLog(logEntry)

        // Verify it was written
        let logFileURL = try manager.getCurrentLogFileURL()
        let logContent = try String(contentsOf: logFileURL, encoding: .utf8)

        #expect(logContent.contains("This should be written successfully"))
    }
}
