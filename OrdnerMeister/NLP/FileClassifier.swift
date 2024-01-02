//
//  FileClassifier.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 01.01.2024.
//

import Bayes
import Foundation
import NaturalLanguage
import OSLog

class FileClassifier {
    typealias FolderURL = URL
    typealias TextualContent = String

    private var bayesianClassifier: BayesianClassifier<FolderURL, TextualContent>?

    func train(using rootNode: Node) {
        Logger.nlp.info("Start training classifier")

        let (folderURLStringList, textualContentList) = createDictionary(from: rootNode)

        var eventSpace = EventSpace<FolderURL, TextualContent>()

        for (folderURL, textualContent) in zip(folderURLStringList, textualContentList) {
            let category = folderURL
            let features = retrieveTokens(from: textualContent)
            eventSpace.observe(category, features: features)
        }

        bayesianClassifier = BayesianClassifier(eventSpace: eventSpace)
    }

    func evaluate(_ textualContent: TextualContent) -> FolderURL? {
        let features = retrieveTokens(from: textualContent)
        return bayesianClassifier?.classify(features)
    }

    private func retrieveTokens(from text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        var tokens = [String]()

        tokenizer.enumerateTokens(in: text.startIndex ..< text.endIndex) { tokenRange, _ -> Bool in
            let token = String(text[tokenRange].lowercased())
            tokens.append(token)
            return true
        }

        return tokens
    }

    private func createDictionary(from rootNode: Node) -> ([FolderURL], [TextualContent]) {
        var folderURL = [FolderURL]()
        var textualContentList = [TextualContent]()
        var queue = [Node]()
        queue.append(rootNode)

        while !queue.isEmpty {
            let current = queue.removeFirst()

            if let textualContent = current.textualContent {
                let parentURL = current.url
                    .deletingLastPathComponent()
                folderURL.append(parentURL)
                textualContentList.append(textualContent)
            }

            current.children.forEach { child in
                queue.append(child.value)
            }
        }

        return (folderURL, textualContentList)
    }
}
