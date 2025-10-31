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
        let destinationFolder = destination.deletingLastPathComponent().lastPathComponent

        logger.info("Moving file '\(fileName)' to '\(destinationFolder)'")

        do {
            try await fileRepository.copyFile(from: file, to: destination)
            logger.info("Successfully moved '\(fileName)' to '\(destinationFolder)'")
        } catch {
            logger.error("Failed to move '\(fileName)' to '\(destinationFolder)': \(error.localizedDescription)")
            throw error
        }
    }
}
