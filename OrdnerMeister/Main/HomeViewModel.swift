//
//  HomeViewModel.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 29.12.2023.
//

import Combine
import Foundation
import OSLog

@Observable
class HomeViewModel {
    private let fileOrchestrator: FileOrchestrating
    private var settingsDefaults: SettingsStoring
    private var cancellables = Set<AnyCancellable>()
    var actionableFiles: [FilePrediction]

    init(
        fileOrchestrator: FileOrchestrating = FileOrchestrator(),
        settingsDefaults: SettingsStoring = SettingsDefaults()
    ) {
        self.fileOrchestrator = fileOrchestrator
        self.settingsDefaults = settingsDefaults
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
                try fileOrchestrator.trainAndClassify()
            } catch {
                Logger.general.error("\(error)")
            }

            Logger.general.info("Done processing folders")
        }
    }

    func onPredictionClick(fileURL: URL, targetFolderURL: URL) {
        Task {
            do {
                try fileOrchestrator.copyFile(from: fileURL, to: targetFolderURL)
                actionableFiles.removeAll { $0.file == fileURL }
            } catch {
                Logger.general.error("\(error)")
            }
        }
    }
}
