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
    private let treeBuilder: TreeBuilder
    private let textScrapper: TextScrapper
    private let fileClassifier: FileClassifier
    var inboxDirectory: String
    var outputDirectory: String

    init(treeBuilder: TreeBuilder = TreeBuilder(),
         textScrapper: TextScrapper = TextScrapper(),
         fileClassifier: FileClassifier = FileClassifier())
    {
        self.treeBuilder = treeBuilder
        self.textScrapper = textScrapper
        self.fileClassifier = fileClassifier
        inboxDirectory = String.Empty
        outputDirectory = String.Empty
    }

    func processFolders() {
        Logger.general.info("Start processing folders")

        do {
            guard let inboxDirURL = URL(string: inboxDirectory),
                  let outputDirURL = URL(string: outputDirectory)
            else {
                return
            }

            // Train classifier
            let outputDirTree = try treeBuilder.buildTree(from: outputDirURL)
            let outputDataTable = textScrapper.extractTextFromFiles(from: outputDirTree)

            fileClassifier.train(with: outputDataTable)

            // Read inbox
            let inboxDirTree = try treeBuilder.buildTree(from: inboxDirURL)
            let inboxDataTable = textScrapper.extractTextFromFiles(from: inboxDirTree)

            // Evaluate
            inboxDataTable.textualContent.forEach { text in
                let prediction = fileClassifier.evaluate(text)
                Logger.general.info("✅ Prediction: \(prediction?.absoluteString ?? "N/A")")
            }
        } catch {
            Logger.general.error("\(error)")
        }

        Logger.general.info("Done processing folders")
    }
}
