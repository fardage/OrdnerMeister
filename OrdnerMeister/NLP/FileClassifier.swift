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

    func train(with instances: [Instance]) {
        Logger.nlp.info("Start training classifier")

        var eventSpace = EventSpace<URL, String>()

        instances.forEach { instance in
            let tokens = instance.textualContent.tokenize()
            eventSpace.observe(instance.targetURL, features: tokens)
        }

        bayesianClassifier = BayesianClassifier(eventSpace: eventSpace)
    }

    func evaluate(_ textualContent: String, firstN: Int = 1) throws -> [URL] {
        guard let bayesianClassifier else {
            Logger.nlp.error("Classifier not trained")
            throw ClassifierError.notTrained
        }

        let features = textualContent.tokenize()
        return bayesianClassifier.classify(features, firstN: firstN)
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

// MARK: - BayesianClassifier

public extension BayesianClassifier {
    func classify<S: Sequence>(_ features: S, firstN: Int) -> [Category] where S.Iterator.Element == Feature {
        let categoryProbabilities = categoryProbabilities(features)
        let sorted = categoryProbabilities.sorted { $0.value > $1.value }
        let firstN = sorted.prefix(firstN)
        return firstN.map(\.key)
    }
}
