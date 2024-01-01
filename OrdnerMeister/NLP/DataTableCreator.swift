//
//  DataTableCreator.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 01.01.2024.
//

import CreateML
import Foundation

struct DataTableCreator {
    typealias FolderURLString = String
    typealias TextualContent = String

    static let folderURLColumnName = "folderURL"
    static let textualContentColumnName = "textualContent"

    func createDataTable(from rootNode: Node) throws -> MLDataTable {
        let (folderURLStringList, textualContentList) = createDictionary(from: rootNode)

        let dataTable = try MLDataTable(dictionary: [
            DataTableCreator.folderURLColumnName: folderURLStringList,
            DataTableCreator.textualContentColumnName: textualContentList,
        ])

        return dataTable
    }

    private func createDictionary(from rootNode: Node) -> ([FolderURLString], [TextualContent]) {
        var folderURLStringList = [FolderURLString]()
        var textualContentList = [TextualContent]()
        var queue = [Node]()
        queue.append(rootNode)

        while !queue.isEmpty {
            let current = queue.removeFirst()

            if let textualContent = current.textualContent {
                let parentURL = current.url
                    .deletingLastPathComponent()
                    .absoluteString
                folderURLStringList.append(parentURL)
                textualContentList.append(textualContent)
            }

            current.children.forEach { child in
                queue.append(child.value)
            }
        }

        return (folderURLStringList, textualContentList)
    }
}
