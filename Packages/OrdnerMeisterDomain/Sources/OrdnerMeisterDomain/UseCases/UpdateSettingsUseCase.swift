import Foundation

/// Use case for updating application settings
public protocol UpdateSettingsUseCaseProtocol {
    func updateInboxPath(_ path: DirectoryPath) throws
    func updateOutputPath(_ path: DirectoryPath) throws
    func updateExclusions(_ exclusions: [DirectoryPath]) throws
    func updateFileOperationMode(_ mode: FileOperationMode) throws
}

public final class UpdateSettingsUseCase: UpdateSettingsUseCaseProtocol, @unchecked Sendable {
    private let settingsRepository: SettingsRepositoryProtocol

    public init(settingsRepository: SettingsRepositoryProtocol) {
        self.settingsRepository = settingsRepository
    }

    public func updateInboxPath(_ path: DirectoryPath) throws {
        try settingsRepository.updateInboxPath(path)
    }

    public func updateOutputPath(_ path: DirectoryPath) throws {
        try settingsRepository.updateOutputPath(path)
    }

    public func updateExclusions(_ exclusions: [DirectoryPath]) throws {
        try settingsRepository.updateExclusions(exclusions)
    }

    public func updateFileOperationMode(_ mode: FileOperationMode) throws {
        try settingsRepository.updateFileOperationMode(mode)
    }
}
