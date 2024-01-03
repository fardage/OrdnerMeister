//
//  FileClassifierTests.swift
//  OrdnerMeisterTests
//
//  Created by Marvin Tseng on 03.01.2024.
//

@testable import OrdnerMeister
import XCTest

final class FileClassifierTests: XCTestCase {
    func testTokenize() {
        let input = "Hello, World!"
        let expectedOutput = ["hello", "world"]

        let result = input.tokenize()

        XCTAssertEqual(result, expectedOutput)
    }
}
