//
//  TextScrapperTests.swift
//  OrdnerMeisterTests
//
//  Created by Marvin Tseng on 31.12.2023.
//

import Foundation
import Mockingbird

@testable import OrdnerMeister
import XCTest

class TextScrapperTests: XCTestCase {
    func test_ShouldExtractTextOfDummyPDF() {
        let pdfURL = URL(string: "foo.pdf")!
        let pdfContent = "Dummy PDF file"
        let pdfKitWrapperMock = mock(PDFKitWrapping.self)
        given(pdfKitWrapperMock.extractText(from: any())).willReturn(pdfContent)

        let textScrapper = TextScrapper(pdfKitWrapper: pdfKitWrapperMock)

        let node = Node(url: pdfURL, children: [:])
        let result = textScrapper.extractTextFromFiles(from: node)

        XCTAssertEqual(result.textualContent, pdfContent)

        verify(pdfKitWrapperMock.extractText(from: pdfURL)).wasCalled()
    }
}
