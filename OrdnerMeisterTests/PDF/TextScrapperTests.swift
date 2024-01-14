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

        let textStoreMock = mock(TextStoring.self)
        given(textStoreMock.getCache()).willReturn([:])

        let textScrapper = TextScrapper(pdfKitWrapper: pdfKitWrapperMock, textStore: textStoreMock)

        let node = Node(url: pdfURL, children: [:])
        let result = textScrapper.extractText(from: node)

        XCTAssertEqual(result.textualContent.first, pdfContent)

        verify(pdfKitWrapperMock.extractText(from: pdfURL)).wasCalled()
    }
}
