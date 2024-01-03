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

    func train(with categories: [FolderURL], and features: [TextualContent]) {
        Logger.nlp.info("Start training classifier")

        var eventSpace = EventSpace<FolderURL, TextualContent>()

        for (category, feature) in zip(categories, features) {
            let tokens = retrieveTokens(from: feature)
            eventSpace.observe(category, features: tokens)
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
}
