//
//  ConfigurationViewModel.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 29.12.2023.
//

import Combine
import Foundation
import OSLog

@Observable
class ConfigurationViewModel {
    private let fileOrchestrator: FileOrchestrating
    private var cancellables = Set<AnyCancellable>()
    var actionableFiles: [FilePrediction]
    var inboxDirectory: String
    var outputDirectory: String

    init(fileOrchestrator: FileOrchestrating = FileOrchestrator()) {
        self.fileOrchestrator = fileOrchestrator
        inboxDirectory = String.Empty
        outputDirectory = String.Empty
        actionableFiles = .init()

        observeFilePredictions()
    }

    private func observeFilePredictions() {
        fileOrchestrator.lastPredictions.sink { [weak self] in
            self?.actionableFiles = $0
        }
        .store(in: &cancellables)
    }

    func processFolders() {
        Task {
            Logger.general.info("Start processing folders")

            do {
                try fileOrchestrator.trainAndClassify(
                    inboxDirString: inboxDirectory,
                    outputDirString: outputDirectory
                )
            } catch {
                Logger.general.error("\(error)")
            }

            Logger.general.info("Done processing folders")
        }
    }
}
