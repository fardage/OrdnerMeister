import Foundation

/// Configuration settings for file processing operations
public struct ProcessingConfiguration: Sendable {
    /// Maximum number of concurrent file processing tasks
    public let maxConcurrentTasks: Int

    /// Default configuration with balanced concurrency
    public static let `default` = ProcessingConfiguration(maxConcurrentTasks: 8)

    /// Conservative configuration for lower-end machines
    public static let conservative = ProcessingConfiguration(maxConcurrentTasks: 4)

    /// Aggressive configuration for powerful machines
    public static let aggressive = ProcessingConfiguration(maxConcurrentTasks: 16)

    public init(maxConcurrentTasks: Int) {
        self.maxConcurrentTasks = max(1, maxConcurrentTasks) // Ensure at least 1
    }
}
