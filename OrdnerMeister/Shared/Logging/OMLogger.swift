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

    static let general = Logger(subsystem: subsystem, category: "general")
    static let fileProcessing = Logger(subsystem: subsystem, category: "file processing")
    static let nlp = Logger(subsystem: subsystem, category: "nlp")
    static let view = Logger(subsystem: subsystem, category: "view")
}
