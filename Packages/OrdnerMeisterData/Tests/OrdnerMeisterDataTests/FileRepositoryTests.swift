import Testing
import Foundation
@testable import OrdnerMeisterData
@testable import OrdnerMeisterDomain

@Suite("FileRepository Tests")
struct FileRepositoryTests {

    // MARK: - Test Helpers

    /// Creates a temporary directory with test files
    private func createTestDirectory(with files: [String: String]) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        for (filename, content) in files {
            let fileURL = tempDir.appendingPathComponent(filename)
            if filename.hasSuffix(".pdf") {
                // Create empty PDF file (just for testing file discovery)
                try content.data(using: .utf8)?.write(to: fileURL)
            } else {
                // Create regular text files
                try content.data(using: .utf8)?.write(to: fileURL)
            }
        }

        return tempDir
    }

    /// Cleanup test directory
    private func cleanupDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - PDF Filtering Tests

    @Test("getFiles returns only PDF files when filtering enabled")
    func getFilesReturnsOnlyPDFs() async throws {
        // Given - directory with mixed file types
        let testDir = try createTestDirectory(with: [
            "document.pdf": "PDF content",
            "notes.txt": "Text content",
            "image.jpg": "Image data",
            "contract.pdf": "Contract PDF",
            "readme.md": "Markdown"
        ])
        defer { cleanupDirectory(testDir) }

        let repository = FileRepository()
        let dirPath = try DirectoryPath(string: testDir.path + "/")

        // When - getting files with PDF filter
        let files = try await repository.getFiles(from: dirPath, fileExtensions: [".pdf"])

        // Then - should only return PDF files
        #expect(files.count == 2)
        #expect(files.allSatisfy { $0.pathExtension == "pdf" })
    }

    @Test("getFiles returns all files when no filter specified")
    func getFilesReturnsAllFilesWithoutFilter() async throws {
        // Given - directory with mixed file types
        let testDir = try createTestDirectory(with: [
            "document.pdf": "PDF content",
            "notes.txt": "Text content",
            "image.jpg": "Image data"
        ])
        defer { cleanupDirectory(testDir) }

        let repository = FileRepository()
        let dirPath = try DirectoryPath(string: testDir.path + "/")

        // When - getting files without filter
        let files = try await repository.getFiles(from: dirPath)

        // Then - should return all files
        #expect(files.count == 3)
    }

    @Test("getFiles handles empty directory")
    func getFilesHandlesEmptyDirectory() async throws {
        // Given - empty directory
        let testDir = try createTestDirectory(with: [:])
        defer { cleanupDirectory(testDir) }

        let repository = FileRepository()
        let dirPath = try DirectoryPath(string: testDir.path + "/")

        // When - getting files
        let files = try await repository.getFiles(from: dirPath)

        // Then - should return empty array
        #expect(files.isEmpty)
    }

    @Test("getFiles filters multiple extensions")
    func getFiltersMultipleExtensions() async throws {
        // Given - directory with various file types
        let testDir = try createTestDirectory(with: [
            "document.pdf": "PDF",
            "notes.txt": "Text",
            "data.json": "JSON",
            "style.css": "CSS",
            "report.pdf": "Report"
        ])
        defer { cleanupDirectory(testDir) }

        let repository = FileRepository()
        let dirPath = try DirectoryPath(string: testDir.path + "/")

        // When - filtering for PDF and JSON
        let files = try await repository.getFiles(from: dirPath, fileExtensions: [".pdf", ".json"])

        // Then - should return only PDF and JSON files
        #expect(files.count == 3)
        #expect(files.allSatisfy { $0.pathExtension == "pdf" || $0.pathExtension == "json" })
    }
}
