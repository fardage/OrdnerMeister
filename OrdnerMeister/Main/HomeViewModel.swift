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
    enum Status {
        case ready, busy, done

        var description: String {
            switch self {
            case .ready:
                "Ready"
            case .busy:
                "Processing Files"
            case .done:
                "Done"
            }
        }
    }

    private let fileOrchestrator: FileOrchestrating
    private var cancellables = Set<AnyCancellable>()
    var currentStatus: HomeViewModel.Status
    var actionableFiles: [FilePrediction]
    var isBusy: Bool {
        switch currentStatus {
        case .ready:
            false
        case .busy:
            true
        case .done:
            false
        }
    }

    init(
        fileOrchestrator: FileOrchestrating
    ) {
        self.fileOrchestrator = fileOrchestrator
        currentStatus = .ready
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
            currentStatus = .busy
            do {
                try fileOrchestrator.trainAndClassify()
            } catch {
                Logger.general.error("\(error)")
            }
            currentStatus = .done
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
