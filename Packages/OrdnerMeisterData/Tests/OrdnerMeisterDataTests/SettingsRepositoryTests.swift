import Testing
import Foundation
@testable import OrdnerMeisterData
@testable import OrdnerMeisterDomain

@Suite("SettingsRepository Tests")
struct SettingsRepositoryTests {

    // MARK: - Test Helpers

    /// Creates an in-memory UserDefaults for test isolation
    private func makeTestUserDefaults() -> UserDefaults {
        let suiteName = "test.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        return userDefaults
    }

    /// Creates a test directory path with trailing slash for directory validation
    private func makeTestDirectoryPath(_ path: String) throws -> DirectoryPath {
        // Ensure path has trailing slash to pass hasDirectoryPath validation
        let normalizedPath = path.hasSuffix("/") ? path : path + "/"
        return try DirectoryPath(string: normalizedPath)
    }

    // MARK: - getSettings() Tests

    @Test("getSettings returns stored inbox and output directories")
    func getSettingsReturnsStoredPaths() throws {
        // Given
        let userDefaults = makeTestUserDefaults()
        // Note: Storing with trailing slash, but URL.path normalizes it
        userDefaults.set("/Users/test/Inbox/", forKey: "inboxDirectory")
        userDefaults.set("/Users/test/Output/", forKey: "outputDirectory")

        let repository = SettingsRepository(userDefaults: userDefaults)

        // When
        let settings = repository.getSettings()

        // Then - URL.path removes trailing slash
        #expect(settings.inboxPath.url.path == "/Users/test/Inbox")
        #expect(settings.outputPath.url.path == "/Users/test/Output")
        #expect(settings.exclusions.isEmpty)
    }

    @Test("getSettings returns default paths when nothing is stored")
    func getSettingsReturnsDefaultPaths() throws {
        // Given
        let userDefaults = makeTestUserDefaults()
        let repository = SettingsRepository(userDefaults: userDefaults)

        // When
        let settings = repository.getSettings()

        // Then - should return default Downloads and Documents folders
        #expect(settings.inboxPath.url.path.contains("Downloads"))
        #expect(settings.outputPath.url.path.contains("Documents"))
        #expect(settings.exclusions.isEmpty)
    }

    @Test("getSettings returns stored exclusions")
    func getSettingsReturnsStoredExclusions() throws {
        // Given
        let userDefaults = makeTestUserDefaults()
        userDefaults.set(["/Users/test/Excluded1/", "/Users/test/Excluded2/"],
                        forKey: "excludedDirectories")

        let repository = SettingsRepository(userDefaults: userDefaults)

        // When
        let settings = repository.getSettings()

        // Then - URL.path removes trailing slash
        #expect(settings.exclusions.count == 2)
        #expect(settings.exclusions[0].url.path == "/Users/test/Excluded1")
        #expect(settings.exclusions[1].url.path == "/Users/test/Excluded2")
    }

    // MARK: - updateInboxPath() Tests

    @Test("updateInboxPath persists inbox directory to UserDefaults")
    func updateInboxPathPersistsToUserDefaults() throws {
        // Given
        let userDefaults = makeTestUserDefaults()
        let repository = SettingsRepository(userDefaults: userDefaults)
        let newPath = try makeTestDirectoryPath("/Users/test/NewInbox")

        // When
        try repository.updateInboxPath(newPath)

        // Then - Repository stores with trailing slash for directory validation
        let storedPath = userDefaults.string(forKey: "inboxDirectory")
        #expect(storedPath == "/Users/test/NewInbox/")

        // Verify getSettings returns updated path (URL.path normalizes it)
        let settings = repository.getSettings()
        #expect(settings.inboxPath.url.path == "/Users/test/NewInbox")
    }

    // MARK: - updateOutputPath() Tests

    @Test("updateOutputPath persists output directory to UserDefaults")
    func updateOutputPathPersistsToUserDefaults() throws {
        // Given
        let userDefaults = makeTestUserDefaults()
        let repository = SettingsRepository(userDefaults: userDefaults)
        let newPath = try makeTestDirectoryPath("/Users/test/NewOutput")

        // When
        try repository.updateOutputPath(newPath)

        // Then - Repository stores with trailing slash for directory validation
        let storedPath = userDefaults.string(forKey: "outputDirectory")
        #expect(storedPath == "/Users/test/NewOutput/")

        // Verify getSettings returns updated path (URL.path normalizes it)
        let settings = repository.getSettings()
        #expect(settings.outputPath.url.path == "/Users/test/NewOutput")
    }

    // MARK: - updateExclusions() Tests

    @Test("updateExclusions persists excluded directories to UserDefaults")
    func updateExclusionsPersistsToUserDefaults() throws {
        // Given
        let userDefaults = makeTestUserDefaults()
        let repository = SettingsRepository(userDefaults: userDefaults)
        let exclusions = [
            try makeTestDirectoryPath("/Users/test/Excluded1"),
            try makeTestDirectoryPath("/Users/test/Excluded2"),
            try makeTestDirectoryPath("/Users/test/Excluded3")
        ]

        // When
        try repository.updateExclusions(exclusions)

        // Then - Repository stores with trailing slashes for directory validation
        let storedPaths = userDefaults.array(forKey: "excludedDirectories") as? [String]
        #expect(storedPaths?.count == 3)
        #expect(storedPaths?[0] == "/Users/test/Excluded1/")
        #expect(storedPaths?[1] == "/Users/test/Excluded2/")
        #expect(storedPaths?[2] == "/Users/test/Excluded3/")

        // Verify getSettings returns updated exclusions (URL.path normalizes them)
        let settings = repository.getSettings()
        #expect(settings.exclusions.count == 3)
    }

    @Test("updateExclusions with empty array clears exclusions")
    func updateExclusionsWithEmptyArrayClearsExclusions() throws {
        // Given
        let userDefaults = makeTestUserDefaults()
        userDefaults.set(["/Users/test/Excluded1/"], forKey: "excludedDirectories")
        let repository = SettingsRepository(userDefaults: userDefaults)

        // When
        try repository.updateExclusions([])

        // Then
        let storedPaths = userDefaults.array(forKey: "excludedDirectories") as? [String]
        #expect(storedPaths?.isEmpty == true)

        // Verify getSettings returns no exclusions
        let settings = repository.getSettings()
        #expect(settings.exclusions.isEmpty)
    }

    // MARK: - Integration Tests

    @Test("Multiple updates persist correctly")
    func multipleUpdatesPersistCorrectly() throws {
        // Given
        let userDefaults = makeTestUserDefaults()
        let repository = SettingsRepository(userDefaults: userDefaults)

        // When - update inbox
        let newInbox = try makeTestDirectoryPath("/Users/test/Inbox")
        try repository.updateInboxPath(newInbox)

        // When - update output
        let newOutput = try makeTestDirectoryPath("/Users/test/Output")
        try repository.updateOutputPath(newOutput)

        // When - update exclusions
        let exclusions = [try makeTestDirectoryPath("/Users/test/Excluded")]
        try repository.updateExclusions(exclusions)

        // Then - create new repository instance to verify persistence
        let newRepository = SettingsRepository(userDefaults: userDefaults)
        let settings = newRepository.getSettings()

        // URL.path removes trailing slash
        #expect(settings.inboxPath.url.path == "/Users/test/Inbox")
        #expect(settings.outputPath.url.path == "/Users/test/Output")
        #expect(settings.exclusions.count == 1)
        #expect(settings.exclusions[0].url.path == "/Users/test/Excluded")
    }
}
