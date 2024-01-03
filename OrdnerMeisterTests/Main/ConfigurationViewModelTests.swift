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
        let viewModel = ConfigurationViewModel(fileOrchestrator: fileOrchestratorMock)
        viewModel.inboxDirectory = "inbox"
        viewModel.outputDirectory = "output"

        // When
        viewModel.processFolders()

        // Then
        verify(fileOrchestratorMock.trainAndClassify(inboxDirString: "inbox", outputDirString: "output")).wasCalled()
    }
}
