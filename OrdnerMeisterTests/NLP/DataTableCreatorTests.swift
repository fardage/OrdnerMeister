//
//  DataTableCreatorTests.swift
//  OrdnerMeisterTests
//
//  Created by Marvin Tseng on 01.01.2024.
//

import CreateML
@testable import OrdnerMeister
import XCTest

final class DataTableCreatorTests: XCTestCase {
    func testCreateDataTable() throws {
        // Arrange
        let rootNode = Node(url: URL(string: "file://foo/bar")!, textualContent: "Example Text", children: [:])
        let expectedFolderURLStringList = ["file://foo/bar"]
        let expectedTextualContentList = ["Example Text"]

        // Act
        let dataTableCreator = DataTableCreator()
        let dataTable = try dataTableCreator.createDataTable(from: rootNode)

        // Assert
        let columnNames = dataTable.columnNames
            .sorted()
            .map { String(describing: $0) }
        XCTAssertEqual(columnNames, [DataTableCreator.folderURLColumnName, DataTableCreator.textualContentColumnName])
    }
}
