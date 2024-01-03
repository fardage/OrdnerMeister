//
//  PDFKitWrapperTests.swift
//  OrdnerMeisterTests
//
//  Created by Marvin Tseng on 03.01.2024.
//

@testable import OrdnerMeister
import XCTest

final class PDFKitWrapperTests: XCTestCase {
    func testExtractText() throws {
        // Given
        let url = Bundle(for: type(of: self)).url(forResource: "dummy", withExtension: "pdf")!
        let wrapper = PDFKitWrapper()

        // When
        let extractedText = wrapper.extractText(from: url)

        // Then
        XCTAssertEqual(extractedText, "Dummy PDF file\n")
    }
}
