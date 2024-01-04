//
//  FileOrchestrator.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 03.01.2024.
//

import Foundation
import OSLog

protocol FileOrchestrating {
    func trainAndClassify(inboxDirString: String, outputDirString: String) throws
}

struct FileOrchestrator: FileOrchestrating {
    private let treeBuilder: TreeBuilder
    private let textScrapper: TextScrapper
    private let fileClassifier: FileClassifier

    init(treeBuilder: TreeBuilder = TreeBuilder(),
         textScrapper: TextScrapper = TextScrapper(),
         fileClassifier: FileClassifier = FileClassifier())
    {
        self.treeBuilder = treeBuilder
        self.textScrapper = textScrapper
        self.fileClassifier = fileClassifier
    }

    func trainAndClassify(inboxDirString: String, outputDirString: String) throws {
        do {
            guard let inboxDirURL = URL(string: inboxDirString),
                  let outputDirURL = URL(string: outputDirString)
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
            try inboxDataTable.textualContent.forEach { text in
                let prediction = try fileClassifier.evaluate(text, firstN: 3)
                Logger.general.info("✅ Prediction: \(String(describing: prediction))")
            }
        } catch {
            Logger.fileProcessing.error("\(error)")
        }
    }
}
