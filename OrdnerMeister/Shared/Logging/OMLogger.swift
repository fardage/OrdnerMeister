//
//  OMLogger.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 30.12.2023.
//

import Foundation
import OSLog

extension Logger {
    private static var subsystem = "ch.tseng.OrdnerMeister"

    // Existing categories
    static let general = Logger(subsystem: subsystem, category: "general")
    static let fileProcessing = Logger(subsystem: subsystem, category: "file processing")
    static let nlp = Logger(subsystem: subsystem, category: "nlp")
    static let view = Logger(subsystem: subsystem, category: "view")

    // New categories for enhanced logging
    static let processing = Logger(subsystem: subsystem, category: "Processing")
    static let ocr = Logger(subsystem: subsystem, category: "OCR")
    static let classifier = Logger(subsystem: subsystem, category: "Classifier")
    static let fileSystem = Logger(subsystem: subsystem, category: "FileSystem")
    static let settings = Logger(subsystem: subsystem, category: "Settings")
}
