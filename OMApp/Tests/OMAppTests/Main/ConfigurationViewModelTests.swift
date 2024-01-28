//
//  ConfigurationViewModelTests.swift
//  OrdnerMeisterTests
//
//  Created by Marvin Tseng on 03.01.2024.
//

import Mockingbird
@testable import OrdnerMeister
import XCTest

final class ConfigurationViewModelTests: XCTestCase {
    func testProcessFolders() {
        // Given
        let fileOrchestratorMock = mock(FileOrchestrating.self)
        given(fileOrchestratorMock.getLastPredictions()).willReturn(.constant([]))

        // When
        let viewModel = HomeViewModel(fileOrchestrator: fileOrchestratorMock)
        viewModel.processFolders()

        // Then
        eventually {
            verify(fileOrchestratorMock.trainAndClassify())
                .wasCalled()
        }

        waitForExpectations(timeout: 10)
    }

    func testCopyFile() {
        // Given
        let fileOrchestratorMock = mock(FileOrchestrating.self)
        given(fileOrchestratorMock.getLastPredictions()).willReturn(.constant([]))

        // When
        let viewModel = HomeViewModel(fileOrchestrator: fileOrchestratorMock)
        let fileURL = URL(string: "file://foo/bar")!
        let targetFolderURL = URL(string: "file://foo/bar")!
        viewModel.onPredictionClick(fileURL: fileURL, targetFolderURL: targetFolderURL)

        // Then
        eventually {
            verify(fileOrchestratorMock.copyFile(
                from: fileURL,
                to: targetFolderURL
            )
            )
            .wasCalled()
        }

        waitForExpectations(timeout: 10)
    }
}
