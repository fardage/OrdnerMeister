//
//  ConfigurationViewModel.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 29.12.2023.
//

import Foundation
import OSLog

@Observable
class ConfigurationViewModel {
    private let fileOrchestrator: FileOrchestrating
    var inboxDirectory: String
    var outputDirectory: String

    init(fileOrchestrator: FileOrchestrating = FileOrchestrator()) {
        self.fileOrchestrator = fileOrchestrator
        inboxDirectory = String.Empty
        outputDirectory = String.Empty
    }

    func processFolders() {
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
