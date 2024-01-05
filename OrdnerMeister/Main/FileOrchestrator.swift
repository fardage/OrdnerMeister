//
//  FileOrchestrator.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 03.01.2024.
//

import Combine
import Foundation
import OSLog

protocol FileOrchestrating {
    var lastPredictions: DomainProperty<[FilePrediction]> { get }
    func trainAndClassify(inboxDirString: String, outputDirString: String) throws
}

struct FileOrchestrator: FileOrchestrating {
    private let treeBuilder: TreeBuilder
    private let textScrapper: TextScrapper
    private let fileClassifier: FileClassifier
    private let _lastPredictions: CurrentValueSubject<[FilePrediction], Never>

    var lastPredictions: DomainProperty<[FilePrediction]> {
        _lastPredictions.domainProperty()
    }

    init(treeBuilder: TreeBuilder = TreeBuilder(),
         textScrapper: TextScrapper = TextScrapper(),
         fileClassifier: FileClassifier = FileClassifier())
    {
        self.treeBuilder = treeBuilder
        self.textScrapper = textScrapper
        self.fileClassifier = fileClassifier
        _lastPredictions = .init([FilePrediction]())
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
            let outputDataTable = textScrapper.extractText(from: outputDirTree, onFolderLevel: true)

            fileClassifier.train(with: outputDataTable)

            // Read inbox
            let inboxDirTree = try treeBuilder.buildTree(from: inboxDirURL)
            let inboxDataTable = textScrapper.extractText(from: inboxDirTree)

            // Evaluate
            _lastPredictions.value = try zip(inboxDataTable.folderURL, inboxDataTable.textualContent)
                .map { url, text in try (url, fileClassifier.evaluate(text, firstN: 3)) }
                .map { fileURL, predictionURLs in FilePrediction(file: fileURL, predictedOutputFolders: predictionURLs) }

        } catch {
            Logger.fileProcessing.error("\(error)")
        }
    }
}

struct FilePrediction: Identifiable {
    var id: String {
        file.absoluteString
    }

    let file: URL
    let predictedOutputFolders: [URL]
}
