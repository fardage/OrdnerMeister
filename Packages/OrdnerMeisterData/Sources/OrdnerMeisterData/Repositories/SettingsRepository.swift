import Foundation
import Combine
import OrdnerMeisterDomain

/// Concrete implementation of SettingsRepositoryProtocol
public final class SettingsRepository: SettingsRepositoryProtocol {
    private let userDefaults: UserDefaults
    private let settingsSubject: CurrentValueSubject<Settings, Never>

    private enum Keys: String {
        case inboxDirectory
        case outputDirectory
        case excludedDirectories
    }

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // Load initial settings
        let inbox = userDefaults.string(forKey: Keys.inboxDirectory.rawValue)
        let output = userDefaults.string(forKey: Keys.outputDirectory.rawValue)
        let exclusions = userDefaults.array(forKey: Keys.excludedDirectories.rawValue) as? [String] ?? []

        let initialSettings = Self.makeSettings(
            inboxPath: inbox,
            outputPath: output,
            exclusions: exclusions
        )

        self.settingsSubject = CurrentValueSubject(initialSettings)
    }

    public func getSettings() -> Settings {
        settingsSubject.value
    }

    public func observeSettings() -> AnyPublisher<Settings, Never> {
        settingsSubject.eraseToAnyPublisher()
    }

    public func updateInboxPath(_ path: DirectoryPath) throws {
        userDefaults.set(path.url.path, forKey: Keys.inboxDirectory.rawValue)

        let newSettings = Settings(
            inboxPath: path,
            outputPath: settingsSubject.value.outputPath,
            exclusions: settingsSubject.value.exclusions
        )
        settingsSubject.send(newSettings)
    }

    public func updateOutputPath(_ path: DirectoryPath) throws {
        userDefaults.set(path.url.path, forKey: Keys.outputDirectory.rawValue)

        let newSettings = Settings(
            inboxPath: settingsSubject.value.inboxPath,
            outputPath: path,
            exclusions: settingsSubject.value.exclusions
        )
        settingsSubject.send(newSettings)
    }

    public func updateExclusions(_ exclusions: [DirectoryPath]) throws {
        let paths = exclusions.map { $0.url.path }
        userDefaults.set(paths, forKey: Keys.excludedDirectories.rawValue)

        let newSettings = Settings(
            inboxPath: settingsSubject.value.inboxPath,
            outputPath: settingsSubject.value.outputPath,
            exclusions: exclusions
        )
        settingsSubject.send(newSettings)
    }

    // MARK: - Private Helpers

    private static func makeSettings(inboxPath: String?, outputPath: String?, exclusions: [String]) -> Settings {
        // Provide default paths if not set
        let defaultInbox = try? DirectoryPath(string: NSHomeDirectory() + "/Downloads")
        let defaultOutput = try? DirectoryPath(string: NSHomeDirectory() + "/Documents")

        let inbox = inboxPath.flatMap { try? DirectoryPath(string: $0) } ?? defaultInbox!
        let output = outputPath.flatMap { try? DirectoryPath(string: $0) } ?? defaultOutput!
        let excluded = exclusions.compactMap { try? DirectoryPath(string: $0) }

        return Settings(
            inboxPath: inbox,
            outputPath: output,
            exclusions: excluded
        )
    }
}
