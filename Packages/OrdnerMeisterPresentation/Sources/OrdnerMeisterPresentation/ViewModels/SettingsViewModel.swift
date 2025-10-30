import Foundation
import Combine
import OrdnerMeisterDomain

/// ViewModel for the settings screen that manages application configuration
@Observable
public final class SettingsViewModel {
    private let getSettingsUseCase: GetSettingsUseCase
    private let updateSettingsUseCase: UpdateSettingsUseCase

    private var cancellables = Set<AnyCancellable>()

    public var excludedDirectories: [String] = []

    public var inboxDirectory: String {
        get {
            getSettingsUseCase.execute().inboxPath.url.path
        }
        set {
            guard let dirPath = try? DirectoryPath(string: newValue) else { return }
            try? updateSettingsUseCase.updateInboxPath(dirPath)
        }
    }

    public var outputDirectory: String {
        get {
            getSettingsUseCase.execute().outputPath.url.path
        }
        set {
            guard let dirPath = try? DirectoryPath(string: newValue) else { return }
            try? updateSettingsUseCase.updateOutputPath(dirPath)
        }
    }

    public init(
        getSettingsUseCase: GetSettingsUseCase,
        updateSettingsUseCase: UpdateSettingsUseCase
    ) {
        self.getSettingsUseCase = getSettingsUseCase
        self.updateSettingsUseCase = updateSettingsUseCase

        // Observe settings changes
        getSettingsUseCase.observe()
            .sink { [weak self] settings in
                self?.excludedDirectories = settings.exclusions.map { $0.url.path }
            }
            .store(in: &cancellables)
    }

    public func addExcludedDirectory(_ directory: String) {
        guard let dirPath = try? DirectoryPath(string: directory) else { return }

        let currentSettings = getSettingsUseCase.execute()
        var exclusions = currentSettings.exclusions
        exclusions.append(dirPath)

        try? updateSettingsUseCase.updateExclusions(exclusions)
    }

    public func removeExcludedDirectory(_ directory: String) {
        let currentSettings = getSettingsUseCase.execute()
        var exclusions = currentSettings.exclusions
        exclusions.removeAll { $0.url.path == directory }

        try? updateSettingsUseCase.updateExclusions(exclusions)
    }
}
