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
    private typealias FolderURLString = String
    private typealias TextualContent = String

    private var bayesianClassifier: BayesianClassifier<String, String>?

    func train(using rootNode: Node) {
        let (folderURLStringList, textualContentList) = createDictionary(from: rootNode)

        var eventSpace = EventSpace<FolderURLString, TextualContent>()

        for (folderURL, textualContent) in zip(folderURLStringList, textualContentList) {
            let category = folderURL.lowercased()
            let features = retrieveTokens(from: textualContent)
            eventSpace.observe(category, features: features)
        }

        bayesianClassifier = BayesianClassifier(eventSpace: eventSpace)
    }

    func evaluate(_ textualContent: String) -> URL? {
        let features = retrieveTokens(from: textualContent)

        if let prediction = bayesianClassifier?.classify(features) {
            return URL(string: prediction)
        } else {
            return nil
        }
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

    private func createDictionary(from rootNode: Node) -> ([FolderURLString], [TextualContent]) {
        var folderURLStringList = [FolderURLString]()
        var textualContentList = [TextualContent]()
        var queue = [Node]()
        queue.append(rootNode)

        while !queue.isEmpty {
            let current = queue.removeFirst()

            if let textualContent = current.textualContent {
                let parentURL = current.url
                    .deletingLastPathComponent()
                    .absoluteString
                folderURLStringList.append(parentURL)
                textualContentList.append(textualContent)
            }

            current.children.forEach { child in
                queue.append(child.value)
            }
        }

        return (folderURLStringList, textualContentList)
    }
}
