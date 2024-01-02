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
        Task {
            switch result {
            case let .success(directory):
                processFolder(url: directory)
            case let .failure(error):
                Logger.general.error("\(error)")
            }
        }
    }

    private func processFolder(url: URL) {
        Logger.general.info("Start processing folders")

        do {
            let tree = try TreeBuilder().buildTree(from: url)
            let textTree = TextScrapper().extractTextFromFiles(from: tree)

            let fileClassifier = FileClassifier()
            fileClassifier.train(using: textTree)
            let result = fileClassifier.evaluate("Für die Steuerperiode 2023 stellen wir Ihnen die nachfolgende Zahlungsempfehlung als provisorische Rechnung zu.")
            Logger.general.info("\(result?.absoluteString ?? "N/A")")

        } catch {
            Logger.general.error("\(error)")
        }

        Logger.general.info("Done processing folders")
    }
}
