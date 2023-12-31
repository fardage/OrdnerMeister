//
//  TreeBuilderTests.swift
//  OrdnerMeisterTests
//
//  Created by Marvin Tseng on 31.12.2023.
//

@testable import OrdnerMeister
import XCTest

final class TreeBuilderTests: XCTestCase {
    private var fileManager: FileManager!
    private var testDirName = "TestDirectory"
    private var file1Name = "File1.txt"
    private var file2Name = "File2.txt"
    private var subDirName = "SubDirectory"
    private var subFileName = "SubFile.txt"
    private var testDirURL: URL!
    private var treeBuilder: TreeBuilder!

    override func setUpWithError() throws {
        fileManager = FileManager.default

        let tempDirURL = URL(fileURLWithPath: NSTemporaryDirectory())
        testDirURL = tempDirURL.appendingPathComponent(testDirName)
        try fileManager.createDirectory(at: testDirURL, withIntermediateDirectories: true, attributes: nil)

        let file1URL = testDirURL.appendingPathComponent(file1Name)
        try "File 1 contents".write(to: file1URL, atomically: true, encoding: .utf8)

        let file2URL = testDirURL.appendingPathComponent(file2Name)
        try "File 2 contents".write(to: file2URL, atomically: true, encoding: .utf8)

        let subDirURL = testDirURL.appendingPathComponent(subDirName)
        try fileManager.createDirectory(at: subDirURL, withIntermediateDirectories: true, attributes: nil)

        let subFileURL = subDirURL.appendingPathComponent(subFileName)
        try "Sub file contents".write(to: subFileURL, atomically: true, encoding: .utf8)

        treeBuilder = TreeBuilder()
    }

    override func tearDownWithError() throws {
        try fileManager.removeItem(at: testDirURL)
    }

    func testBuildTree() throws {
        let rootNode = try treeBuilder.buildTree(from: testDirURL)

        XCTAssertEqual(rootNode.name, "TestDirectory")
        XCTAssertEqual(rootNode.children.count, 3)

        let file1Node = try XCTUnwrap(rootNode.children["File1.txt"])
        XCTAssertEqual(file1Node.name, "File1.txt")
        XCTAssertTrue(file1Node.children.isEmpty)

        let file2Node = try XCTUnwrap(rootNode.children["File2.txt"])
        XCTAssertEqual(file2Node.name, "File2.txt")
        XCTAssertTrue(file2Node.children.isEmpty)

        let subDirNode = try XCTUnwrap(rootNode.children["SubDirectory"])
        XCTAssertEqual(subDirNode.name, "SubDirectory")
        XCTAssertEqual(subDirNode.children.count, 1)

        let subFileNode = try XCTUnwrap(subDirNode.children["SubFile.txt"])
        XCTAssertEqual(subFileNode.name, "SubFile.txt")
        XCTAssertTrue(subFileNode.children.isEmpty)
    }
}
