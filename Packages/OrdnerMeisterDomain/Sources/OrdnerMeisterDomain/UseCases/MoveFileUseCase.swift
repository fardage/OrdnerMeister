import Foundation

/// Use case for moving a file to a destination folder
public protocol MoveFileUseCaseProtocol {
    func execute(file: URL, to destination: URL) async throws
}

public final class MoveFileUseCase: MoveFileUseCaseProtocol, @unchecked Sendable {
    private let fileRepository: FileRepositoryProtocol

    public init(fileRepository: FileRepositoryProtocol) {
        self.fileRepository = fileRepository
    }

    public func execute(file: URL, to destination: URL) async throws {
        try await fileRepository.copyFile(from: file, to: destination)
    }
}
