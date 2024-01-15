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
    func trainAndClassify() throws
    func copyFile(from sourceURL: URL, to destinationURL: URL) throws
}

struct FileOrchestrator: FileOrchestrating {
    private let settingsService: SettingsService
    private let fileManager: FileManaging
    private let treeBuilder: TreeBuilder
    private let textScrapper: TextScrapper
    private let fileClassifier: FileClassifier
    private let _lastPredictions: CurrentValueSubject<[FilePrediction], Never>

    var lastPredictions: DomainProperty<[FilePrediction]> {
        _lastPredictions.domainProperty()
    }

    init(settingsService: SettingsService = SettingsService(),
         fileManager: FileManaging = FileManager(),
         treeBuilder: TreeBuilder = TreeBuilder(),
         textScrapper: TextScrapper = TextScrapper(),
         fileClassifier: FileClassifier = FileClassifier())
    {
        self.settingsService = settingsService
        self.fileManager = fileManager
        self.treeBuilder = treeBuilder
        self.textScrapper = textScrapper
        self.fileClassifier = fileClassifier
        _lastPredictions = .init([FilePrediction]())
    }

    func trainAndClassify() throws {
        do {
            guard let inboxDir = settingsService.inboxDirectory.currentValue,
                  let inboxDirURL = URL(string: inboxDir),
                  let outputDir = settingsService.outputDirectory.currentValue,
                  let outputDirURL = URL(string: outputDir)
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

    func copyFile(from sourceURL: URL, to folderURL: URL) throws {
        let destinationURL = folderURL.appending(path: sourceURL.lastPathComponent)
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }
}

struct FilePrediction: Identifiable {
    var id: String {
        file.absoluteString
    }

    let file: URL
    let predictedOutputFolders: [URL]
}
