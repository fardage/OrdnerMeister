import Foundation
import OSLog
import OrdnerMeisterDomain

/// ViewModel for the settings screen that manages application configuration
@Observable
public final class SettingsViewModel {
    private let getSettingsUseCase: GetSettingsUseCaseProtocol
    private let updateSettingsUseCase: UpdateSettingsUseCaseProtocol

    private var isInitializing = true

    public var inboxDirectory: String = "" {
        didSet {
            guard !isInitializing else { return }

            do {
                let dirPath = try DirectoryPath(string: inboxDirectory)
                try updateSettingsUseCase.updateInboxPath(dirPath)
            } catch {
                Logger().error("Failed to update inbox directory: \(error.localizedDescription)")
            }
        }
    }

    public var outputDirectory: String = "" {
        didSet {
            guard !isInitializing else { return }

            do {
                let dirPath = try DirectoryPath(string: outputDirectory)
                try updateSettingsUseCase.updateOutputPath(dirPath)
            } catch {
                Logger().error("Failed to update output directory: \(error.localizedDescription)")
            }
        }
    }

    public var excludedDirectories: [String] = []

    public var fileOperationMode: FileOperationMode = .copy {
        didSet {
            guard !isInitializing else { return }

            do {
                try updateSettingsUseCase.updateFileOperationMode(fileOperationMode)
            } catch {
                Logger().error("Failed to update file operation mode: \(error.localizedDescription)")
            }
        }
    }

    public init(
        getSettingsUseCase: GetSettingsUseCaseProtocol,
        updateSettingsUseCase: UpdateSettingsUseCaseProtocol
    ) {
        self.getSettingsUseCase = getSettingsUseCase
        self.updateSettingsUseCase = updateSettingsUseCase

        // Load initial settings synchronously
        refreshSettings()
        isInitializing = false
    }

    public func addExcludedDirectory(_ directory: String) {
        guard let dirPath = try? DirectoryPath(string: directory) else { return }

        let currentSettings = getSettingsUseCase.execute()
        var exclusions = currentSettings.exclusions
        exclusions.append(dirPath)

        try? updateSettingsUseCase.updateExclusions(exclusions)
        refreshSettings()
    }

    public func removeExcludedDirectory(_ directory: String) {
        let currentSettings = getSettingsUseCase.execute()
        var exclusions = currentSettings.exclusions
        exclusions.removeAll { $0.url.path == directory }

        try? updateSettingsUseCase.updateExclusions(exclusions)
        refreshSettings()
    }

    // MARK: - Private Helpers

    private func refreshSettings() {
        let settings = getSettingsUseCase.execute()
        inboxDirectory = settings.inboxPath.url.path
        outputDirectory = settings.outputPath.url.path
        excludedDirectories = settings.exclusions.map { $0.url.path }
        fileOperationMode = settings.fileOperationMode
    }
}
