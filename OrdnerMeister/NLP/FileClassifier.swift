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
    enum ClassifierError: Error {
        case notTrained
    }

    private var bayesianClassifier: BayesianClassifier<URL, String>?

    func train(with dataTable: DataTable) {
        Logger.nlp.info("Start training classifier")

        var eventSpace = EventSpace<URL, String>()

        for (category, feature) in zip(dataTable.folderURL, dataTable.textualContent) {
            let tokens = feature.tokenize()
            eventSpace.observe(category, features: tokens)
        }

        bayesianClassifier = BayesianClassifier(eventSpace: eventSpace)
    }

    func evaluate(_ textualContent: String) throws -> URL? {
        guard let bayesianClassifier else {
            Logger.nlp.error("Classifier not trained")
            throw ClassifierError.notTrained
        }

        let features = textualContent.tokenize()
        return bayesianClassifier.classify(features)
    }
}

// MARK: - Tokenizer

extension String {
    func tokenize() -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = self

        var tokens = [String]()

        tokenizer.enumerateTokens(in: startIndex ..< endIndex) { tokenRange, _ -> Bool in
            let token = String(self[tokenRange].lowercased())
            tokens.append(token)
            return true
        }

        return tokens
    }
}
