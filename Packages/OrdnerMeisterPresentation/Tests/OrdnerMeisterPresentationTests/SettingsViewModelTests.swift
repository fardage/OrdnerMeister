import Testing
import Foundation
@testable import OrdnerMeisterPresentation
@testable import OrdnerMeisterDomain

// MARK: - Mock Use Cases

/// Mock implementation of GetSettingsUseCaseProtocol for testing
final class MockGetSettingsUseCase: GetSettingsUseCaseProtocol {
    var settingsToReturn: Settings
    var executeCallCount = 0

    init(settingsToReturn: Settings) {
        self.settingsToReturn = settingsToReturn
    }

    func execute() -> Settings {
        executeCallCount += 1
        return settingsToReturn
    }
}

/// Mock implementation of UpdateSettingsUseCaseProtocol for testing
final class MockUpdateSettingsUseCase: UpdateSettingsUseCaseProtocol {
    var updateInboxPathCallCount = 0
    var updateOutputPathCallCount = 0
    var updateExclusionsCallCount = 0

    var lastInboxPath: DirectoryPath?
    var lastOutputPath: DirectoryPath?
    var lastExclusions: [DirectoryPath]?

    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "test", code: 1)

    func updateInboxPath(_ path: DirectoryPath) throws {
        updateInboxPathCallCount += 1
        lastInboxPath = path
        if shouldThrowError {
            throw errorToThrow
        }
    }

    func updateOutputPath(_ path: DirectoryPath) throws {
        updateOutputPathCallCount += 1
        lastOutputPath = path
        if shouldThrowError {
            throw errorToThrow
        }
    }

    func updateExclusions(_ exclusions: [DirectoryPath]) throws {
        updateExclusionsCallCount += 1
        lastExclusions = exclusions
        if shouldThrowError {
            throw errorToThrow
        }
    }
}

// MARK: - Test Helpers

extension SettingsViewModelTests {
    /// Creates a test Settings instance
    static func makeTestSettings(
        inboxPath: String = "/Users/test/Inbox/",
        outputPath: String = "/Users/test/Output/",
        exclusions: [String] = []
    ) throws -> Settings {
        // Ensure paths have trailing slash for directory validation
        let normalizedInbox = inboxPath.hasSuffix("/") ? inboxPath : inboxPath + "/"
        let normalizedOutput = outputPath.hasSuffix("/") ? outputPath : outputPath + "/"
        let normalizedExclusions = exclusions.map { $0.hasSuffix("/") ? $0 : $0 + "/" }

        let inbox = try DirectoryPath(string: normalizedInbox)
        let output = try DirectoryPath(string: normalizedOutput)
        let excluded = try normalizedExclusions.map { try DirectoryPath(string: $0) }
        return Settings(inboxPath: inbox, outputPath: output, exclusions: excluded)
    }
}

// MARK: - SettingsViewModel Tests

@Suite("SettingsViewModel Tests")
struct SettingsViewModelTests {

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with settings from use case")
    func viewModelInitializesWithSettings() throws {
        // Given
        let testSettings = try Self.makeTestSettings(
            inboxPath: "/Users/test/Inbox",
            outputPath: "/Users/test/Output",
            exclusions: ["/Users/test/Excluded1", "/Users/test/Excluded2"]
        )
        let getUseCase = MockGetSettingsUseCase(settingsToReturn: testSettings)
        let updateUseCase = MockUpdateSettingsUseCase()

        // When
        let viewModel = SettingsViewModel(
            getSettingsUseCase: getUseCase,
            updateSettingsUseCase: updateUseCase
        )

        // Then - URL.path removes trailing slash
        #expect(viewModel.inboxDirectory == "/Users/test/Inbox")
        #expect(viewModel.outputDirectory == "/Users/test/Output")
        #expect(viewModel.excludedDirectories.count == 2)
        #expect(viewModel.excludedDirectories[0] == "/Users/test/Excluded1")
        #expect(viewModel.excludedDirectories[1] == "/Users/test/Excluded2")
        #expect(getUseCase.executeCallCount == 1)
    }

    @Test("ViewModel initializes with empty exclusions")
    func viewModelInitializesWithEmptyExclusions() throws {
        // Given
        let testSettings = try Self.makeTestSettings(exclusions: [])
        let getUseCase = MockGetSettingsUseCase(settingsToReturn: testSettings)
        let updateUseCase = MockUpdateSettingsUseCase()

        // When
        let viewModel = SettingsViewModel(
            getSettingsUseCase: getUseCase,
            updateSettingsUseCase: updateUseCase
        )

        // Then
        #expect(viewModel.excludedDirectories.isEmpty)
    }

    // MARK: - inboxDirectory Update Tests

    @Test("Updating inboxDirectory calls updateInboxPath use case")
    func updatingInboxDirectoryCallsUseCase() throws {
        // Given
        let testSettings = try Self.makeTestSettings()
        let getUseCase = MockGetSettingsUseCase(settingsToReturn: testSettings)
        let updateUseCase = MockUpdateSettingsUseCase()
        let viewModel = SettingsViewModel(
            getSettingsUseCase: getUseCase,
            updateSettingsUseCase: updateUseCase
        )

        // When - Use home directory as a real path that exists
        let homePath = NSHomeDirectory() + "/"
        viewModel.inboxDirectory = homePath

        // Then - didSet should create DirectoryPath and call use case
        #expect(updateUseCase.updateInboxPathCallCount == 1)
        #expect(updateUseCase.lastInboxPath?.url.path == NSHomeDirectory())
    }

    @Test("Updating inboxDirectory with invalid path does not crash")
    func updatingInboxDirectoryWithInvalidPath() throws {
        // Given
        let testSettings = try Self.makeTestSettings()
        let getUseCase = MockGetSettingsUseCase(settingsToReturn: testSettings)
        let updateUseCase = MockUpdateSettingsUseCase()
        let viewModel = SettingsViewModel(
            getSettingsUseCase: getUseCase,
            updateSettingsUseCase: updateUseCase
        )

        // When - set an invalid path (file URL string instead of path)
        viewModel.inboxDirectory = "file:///Users/test/Invalid"

        // Then - should not call use case with invalid path
        #expect(updateUseCase.updateInboxPathCallCount == 0)
    }

    // MARK: - outputDirectory Update Tests

    @Test("Updating outputDirectory calls updateOutputPath use case")
    func updatingOutputDirectoryCallsUseCase() throws {
        // Given
        let testSettings = try Self.makeTestSettings()
        let getUseCase = MockGetSettingsUseCase(settingsToReturn: testSettings)
        let updateUseCase = MockUpdateSettingsUseCase()
        let viewModel = SettingsViewModel(
            getSettingsUseCase: getUseCase,
            updateSettingsUseCase: updateUseCase
        )

        // When - Use home directory as a real path that exists
        let homePath = NSHomeDirectory() + "/"
        viewModel.outputDirectory = homePath

        // Then - didSet should create DirectoryPath and call use case
        #expect(updateUseCase.updateOutputPathCallCount == 1)
        #expect(updateUseCase.lastOutputPath?.url.path == NSHomeDirectory())
    }

    @Test("Updating outputDirectory with invalid path does not crash")
    func updatingOutputDirectoryWithInvalidPath() throws {
        // Given
        let testSettings = try Self.makeTestSettings()
        let getUseCase = MockGetSettingsUseCase(settingsToReturn: testSettings)
        let updateUseCase = MockUpdateSettingsUseCase()
        let viewModel = SettingsViewModel(
            getSettingsUseCase: getUseCase,
            updateSettingsUseCase: updateUseCase
        )

        // When - set an invalid path
        viewModel.outputDirectory = "file:///Users/test/Invalid"

        // Then - should not call use case with invalid path
        #expect(updateUseCase.updateOutputPathCallCount == 0)
    }

    // MARK: - addExcludedDirectory Tests

    @Test("addExcludedDirectory adds new directory to exclusions")
    func addExcludedDirectoryAddsNewDirectory() throws {
        // Given
        let testSettings = try Self.makeTestSettings(exclusions: ["/Users/test/Excluded1"])
        let getUseCase = MockGetSettingsUseCase(settingsToReturn: testSettings)
        let updateUseCase = MockUpdateSettingsUseCase()
        let viewModel = SettingsViewModel(
            getSettingsUseCase: getUseCase,
            updateSettingsUseCase: updateUseCase
        )

        // When - add real directory path that exists
        let homePath = NSHomeDirectory() + "/"
        viewModel.addExcludedDirectory(homePath)

        // Then - should call use case with both original and new exclusion
        #expect(updateUseCase.updateExclusionsCallCount == 1)
        #expect(updateUseCase.lastExclusions?.count == 2)
    }

    @Test("addExcludedDirectory with invalid path does not crash")
    func addExcludedDirectoryWithInvalidPath() throws {
        // Given
        let testSettings = try Self.makeTestSettings()
        let getUseCase = MockGetSettingsUseCase(settingsToReturn: testSettings)
        let updateUseCase = MockUpdateSettingsUseCase()
        let viewModel = SettingsViewModel(
            getSettingsUseCase: getUseCase,
            updateSettingsUseCase: updateUseCase
        )

        // When - add invalid path
        viewModel.addExcludedDirectory("file:///Users/test/Invalid")

        // Then - should not call use case
        #expect(updateUseCase.updateExclusionsCallCount == 0)
    }

    // MARK: - removeExcludedDirectory Tests

    @Test("removeExcludedDirectory removes directory from exclusions")
    func removeExcludedDirectoryRemovesDirectory() throws {
        // Given
        let testSettings = try Self.makeTestSettings(
            exclusions: ["/Users/test/Excluded1", "/Users/test/Excluded2"]
        )
        let getUseCase = MockGetSettingsUseCase(settingsToReturn: testSettings)
        let updateUseCase = MockUpdateSettingsUseCase()
        let viewModel = SettingsViewModel(
            getSettingsUseCase: getUseCase,
            updateSettingsUseCase: updateUseCase
        )

        // Update mock to return updated settings
        let updatedSettings = try Self.makeTestSettings(
            exclusions: ["/Users/test/Excluded1"]
        )
        getUseCase.settingsToReturn = updatedSettings

        // When - ViewModel stores paths without trailing slash
        viewModel.removeExcludedDirectory("/Users/test/Excluded2")

        // Then - URL.path removes trailing slash
        #expect(updateUseCase.updateExclusionsCallCount == 1)
        #expect(updateUseCase.lastExclusions?.count == 1)
        #expect(viewModel.excludedDirectories.count == 1)
        #expect(viewModel.excludedDirectories[0] == "/Users/test/Excluded1")
    }

    @Test("removeExcludedDirectory removes all matching directories")
    func removeExcludedDirectoryRemovesAllMatching() throws {
        // Given
        let testSettings = try Self.makeTestSettings(
            exclusions: ["/Users/test/Same", "/Users/test/Different", "/Users/test/Same"]
        )
        let getUseCase = MockGetSettingsUseCase(settingsToReturn: testSettings)
        let updateUseCase = MockUpdateSettingsUseCase()
        let viewModel = SettingsViewModel(
            getSettingsUseCase: getUseCase,
            updateSettingsUseCase: updateUseCase
        )

        // Update mock to return updated settings
        let updatedSettings = try Self.makeTestSettings(
            exclusions: ["/Users/test/Different"]
        )
        getUseCase.settingsToReturn = updatedSettings

        // When - remove all instances of "/Users/test/Same"
        viewModel.removeExcludedDirectory("/Users/test/Same")

        // Then
        #expect(updateUseCase.updateExclusionsCallCount == 1)
        #expect(viewModel.excludedDirectories.count == 1)
        #expect(viewModel.excludedDirectories[0] == "/Users/test/Different")
    }

    // MARK: - Error Handling Tests

    @Test("ViewModel handles update errors gracefully")
    func viewModelHandlesUpdateErrorsGracefully() throws {
        // Given
        let testSettings = try Self.makeTestSettings()
        let getUseCase = MockGetSettingsUseCase(settingsToReturn: testSettings)
        let updateUseCase = MockUpdateSettingsUseCase()
        updateUseCase.shouldThrowError = true
        let viewModel = SettingsViewModel(
            getSettingsUseCase: getUseCase,
            updateSettingsUseCase: updateUseCase
        )

        // When - update should throw error but not crash (use real paths)
        let homePath = NSHomeDirectory() + "/"
        viewModel.inboxDirectory = homePath
        viewModel.outputDirectory = homePath

        // Then - should have attempted the updates
        #expect(updateUseCase.updateInboxPathCallCount == 1)
        #expect(updateUseCase.updateOutputPathCallCount == 1)
    }

    // MARK: - Integration Tests

    @Test("Multiple operations update settings correctly")
    func multipleOperationsUpdateSettingsCorrectly() throws {
        // Given
        var testSettings = try Self.makeTestSettings()
        let getUseCase = MockGetSettingsUseCase(settingsToReturn: testSettings)
        let updateUseCase = MockUpdateSettingsUseCase()
        let viewModel = SettingsViewModel(
            getSettingsUseCase: getUseCase,
            updateSettingsUseCase: updateUseCase
        )

        // When - Perform multiple operations
        let homeDir = NSHomeDirectory() + "/"
        let downloadsDir = NSHomeDirectory() + "/Downloads/"

        viewModel.inboxDirectory = homeDir
        viewModel.outputDirectory = downloadsDir
        viewModel.addExcludedDirectory(homeDir)

        // Then - each operation should call its respective use case
        #expect(updateUseCase.updateInboxPathCallCount == 1)
        #expect(updateUseCase.updateOutputPathCallCount == 1)
        #expect(updateUseCase.updateExclusionsCallCount == 1)
    }
}
