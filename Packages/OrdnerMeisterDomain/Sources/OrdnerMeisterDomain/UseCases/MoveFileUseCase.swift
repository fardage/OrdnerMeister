import Foundation
import OSLog

/// Use case for moving a file to a destination folder
public protocol MoveFileUseCaseProtocol {
    func execute(file: URL, to destination: URL) async throws
}

public final class MoveFileUseCase: MoveFileUseCaseProtocol, @unchecked Sendable {
    private let fileRepository: FileRepositoryProtocol
    private let logger = Logger(subsystem: "ch.tseng.OrdnerMeister", category: "FileSystem")

    public init(fileRepository: FileRepositoryProtocol) {
        self.fileRepository = fileRepository
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

        logger.info("Moving file '\(fileName)' to '\(destinationFolder)'")

        do {
            try await fileRepository.copyFile(from: file, to: destinationFilePath)
            logger.info("Successfully moved '\(fileName)' to '\(destinationFolder)'")
        } catch {
            logger.error("Failed to move '\(fileName)' to '\(destinationFolder)': \(error.localizedDescription)")
            throw error
        }
    }
}
