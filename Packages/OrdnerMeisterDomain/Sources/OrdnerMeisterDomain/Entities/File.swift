import Foundation

/// Domain entity representing a file with its content
public struct File: Hashable {
    public let url: URL
    public let name: String
    public let textContent: String

    public init(url: URL, name: String, textContent: String) {
        self.url = url
        self.name = name
        self.textContent = textContent
    }

    public init(url: URL, textContent: String) {
        self.url = url
        self.name = url.lastPathComponent
        self.textContent = textContent
    }
}
