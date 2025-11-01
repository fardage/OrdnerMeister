import Foundation

/// Domain entity representing a folder/directory
public struct Folder: Hashable, Sendable {
    public let url: URL
    public let name: String

    public init(url: URL, name: String) {
        self.url = url
        self.name = name
    }

    public init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
    }

    public var path: String {
        url.path
    }
}
