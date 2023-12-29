//
//  ConfigurationViewModel.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 29.12.2023.
//

import Foundation
import OSLog

@Observable
class ConfigurationViewModel {
    var inputFolder: String
    var outputFolder: String

    init() {
        inputFolder = ""
        outputFolder = ""
    }

    func processFolders() {
        Logger.general.info("Start processing folders")
    }
}
