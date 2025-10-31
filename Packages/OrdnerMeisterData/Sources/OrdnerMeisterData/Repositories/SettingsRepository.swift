import Foundation
import OrdnerMeisterDomain

/// Concrete implementation of SettingsRepositoryProtocol
public final class SettingsRepository: SettingsRepositoryProtocol {
    private let userDefaults: UserDefaults

    private enum Keys: String {
        case inboxDirectory
        case outputDirectory
        case excludedDirectories
    }

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func getSettings() -> Settings {
        let inbox = userDefaults.string(forKey: Keys.inboxDirectory.rawValue)
        let output = userDefaults.string(forKey: Keys.outputDirectory.rawValue)
        let exclusions = userDefaults.array(forKey: Keys.excludedDirectories.rawValue) as? [String] ?? []

        return Self.makeSettings(
            inboxPath: inbox,
            outputPath: output,
            exclusions: exclusions
        )
    }

    public func updateInboxPath(_ path: DirectoryPath) throws {
        // Store with trailing slash to ensure DirectoryPath can load it back
        let pathString = path.url.path.hasSuffix("/") ? path.url.path : path.url.path + "/"
        userDefaults.set(pathString, forKey: Keys.inboxDirectory.rawValue)
    }

    public func updateOutputPath(_ path: DirectoryPath) throws {
        // Store with trailing slash to ensure DirectoryPath can load it back
        let pathString = path.url.path.hasSuffix("/") ? path.url.path : path.url.path + "/"
        userDefaults.set(pathString, forKey: Keys.outputDirectory.rawValue)
    }

    public func updateExclusions(_ exclusions: [DirectoryPath]) throws {
        // Store with trailing slashes to ensure DirectoryPath can load them back
        let paths = exclusions.map { path in
            path.url.path.hasSuffix("/") ? path.url.path : path.url.path + "/"
        }
        userDefaults.set(paths, forKey: Keys.excludedDirectories.rawValue)
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
