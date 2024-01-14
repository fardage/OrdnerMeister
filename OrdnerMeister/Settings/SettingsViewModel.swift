//
//  SettingsViewModel.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 14.01.2024.
//

import Combine
import Foundation

@Observable
class FolderSettingsViewModel {
    private let settingsService: SettingsService
    private var cancellables: Set<AnyCancellable>

    var inboxDirectory: String {
        get {
            settingsService.inboxDirectory.currentValue ?? String.Empty
        }
        set {
            settingsService.setInboxDirectory(newValue)
        }
    }

    var outputDirectory: String {
        get {
            settingsService.outputDirectory.currentValue ?? String.Empty
        }
        set {
            settingsService.setOutputDirectory(newValue)
        }
    }

    init(settingsService: SettingsService = SettingsService()) {
        self.settingsService = settingsService
        cancellables = .init()
    }
}
