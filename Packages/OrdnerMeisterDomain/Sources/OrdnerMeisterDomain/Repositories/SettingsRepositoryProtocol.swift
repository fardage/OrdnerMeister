import Foundation
import Combine

/// Repository protocol for application settings
public protocol SettingsRepositoryProtocol {
    /// Get current settings
    func getSettings() -> Settings

    /// Observe settings changes
    func observeSettings() -> AnyPublisher<Settings, Never>

    /// Update inbox directory
    func updateInboxPath(_ path: DirectoryPath) throws

    /// Update output directory
    func updateOutputPath(_ path: DirectoryPath) throws

    /// Update exclusion list
    func updateExclusions(_ exclusions: [DirectoryPath]) throws
}
