import Foundation
import OSLog

/// Use case for moving a file to a destination folder
public protocol MoveFileUseCaseProtocol {
    func execute(file: URL, to destination: URL) async throws
}

public final class MoveFileUseCase: MoveFileUseCaseProtocol, @unchecked Sendable {
    private let fileRepository: FileRepositoryProtocol
    private let getSettingsUseCase: GetSettingsUseCaseProtocol
    private let logger = Logger(subsystem: "ch.tseng.OrdnerMeister", category: "FileSystem")

    public init(fileRepository: FileRepositoryProtocol, getSettingsUseCase: GetSettingsUseCaseProtocol) {
        self.fileRepository = fileRepository
        self.getSettingsUseCase = getSettingsUseCase
    }

    public func execute(file: URL, to destination: URL) async throws {
        let fileName = file.lastPathComponent
        let destinationFolder = destination.lastPathComponent

        // Construct the full destination file path by appending the filename to the folder
        let destinationFilePath = destination.appendingPathComponent(fileName)

        // Check if file already exists at destination
        if fileRepository.fileExists(at: destinationFilePath) {
            logger.warning("File '\(fileName)' already exists at '\(destinationFolder)'")
            throw FileSystemError.fileAlreadyExists(destinationFilePath)
        }

        // Get current settings to check file operation mode
        let settings = getSettingsUseCase.execute()

        logger.info("Moving file '\(fileName)' to '\(destinationFolder)' (mode: \(settings.fileOperationMode.rawValue))")

        do {
            // Copy file to destination
            try await fileRepository.copyFile(from: file, to: destinationFilePath)
            logger.info("Successfully copied '\(fileName)' to '\(destinationFolder)'")

            // If mode is .move, delete the source file
            if settings.fileOperationMode == .move {
                try await fileRepository.deleteFile(at: file)
                logger.info("Successfully deleted '\(fileName)' from inbox (move mode)")
            }
        } catch {
            logger.error("Failed to move '\(fileName)' to '\(destinationFolder)': \(error.localizedDescription)")
            throw error
        }
    }
}
