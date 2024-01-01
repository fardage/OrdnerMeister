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
    var showFileImporter: Bool

    init() {
        showFileImporter = false
    }

    func onOutputDirectorySelected(_ result: Result<URL, Error>) {
        switch result {
        case let .success(directory):
            guard directory.startAccessingSecurityScopedResource() else { return }

            processFolder(url: directory)

            directory.stopAccessingSecurityScopedResource()
        case let .failure(error):
            Logger.general.error("\(error)")
        }
    }

    private func processFolder(url: URL) {
        Logger.general.info("Start processing folders")

        do {
            let tree = try TreeBuilder().buildTree(from: url)
            _ = TextScrapper().extractTextFromFiles(from: tree)
        } catch {
            Logger.general.error("\(error)")
        }

        Logger.general.info("Done processing folders")
    }
}
