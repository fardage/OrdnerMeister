//
//  FileOrchestrator.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 03.01.2024.
//

import Combine
import Foundation
import OSLog

public protocol FileOrchestrating {
    var lastPredictions: DomainProperty<[FilePrediction]> { get }
    func trainAndClassify() throws
    func copyFile(from sourceURL: URL, to destinationURL: URL) throws
}

public struct FileOrchestrator: FileOrchestrating {
    private let settingsService: SettingsService
    private let fileManager: FileManaging
    private let treeBuilder: TreeBuilder
    private let textScrapper: TextScrapper
    private let fileClassifier: FileClassifier
    private let _lastPredictions: CurrentValueSubject<[FilePrediction], Never>

    public var lastPredictions: DomainProperty<[FilePrediction]> {
        _lastPredictions.domainProperty()
    }

    public init(settingsService: SettingsService,
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

    public func trainAndClassify() throws {
        do {
            guard let inboxDir = settingsService.inboxDirectory.currentValue,
                  let inboxDirURL = URL(string: inboxDir),
                  let outputDir = settingsService.outputDirectory.currentValue,
                  let outputDirURL = URL(string: outputDir)
            else {
                return
            }

            // Train classifier
            let ignoredDirectories = settingsService.excludedOutputDirectories.currentValue
            let outputDirTree = try treeBuilder.getAllURLs(from: outputDirURL, ignoredDirectories: ignoredDirectories)
            let outputObservations = textScrapper.extractText(from: outputDirTree, onFolderLevel: true)

            fileClassifier.train(with: outputObservations)

            // Read inbox
            let inboxDirTree = try treeBuilder.getAllURLs(from: inboxDirURL)
            let inboxData = textScrapper.extractText(from: inboxDirTree)

            // Evaluate
            _lastPredictions.value = inboxData
                .compactMap { try? ($0.targetURL, fileClassifier.evaluate($0.textualContent, firstN: 3)) }
                .map { fileURL, predictionURLs in FilePrediction(file: fileURL, predictedOutputFolders: predictionURLs) }

        } catch {
            Logger.fileProcessing.error("\(error)")
        }
    }

    public func copyFile(from sourceURL: URL, to folderURL: URL) throws {
        let destinationURL = folderURL.appending(path: sourceURL.lastPathComponent)
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }
}

public struct FilePrediction: Identifiable {
    public var id: String {
        file.absoluteString
    }

    let file: URL
    let predictedOutputFolders: [URL]
}
