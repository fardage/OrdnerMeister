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
    var inboxDirectory: String
    var outputDirectory: String

    init() {
        inboxDirectory = String.Empty
        outputDirectory = String.Empty
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
