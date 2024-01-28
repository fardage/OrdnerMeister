//
//  SettingsViewModel.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 14.01.2024.
//

import Combine
import Foundation

@Observable
public class FolderSettingsViewModel {
    private let settingsService: SettingsService
    private var cancellables: Set<AnyCancellable>

    var excludedDirectories: [String]

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

    public init(settingsService: SettingsService = SettingsService()) {
        self.settingsService = settingsService
        excludedDirectories = .init()
        cancellables = .init()

        settingsService.excludedOutputDirectories
            .sink { [weak self] excludedDirs in
                self?.excludedDirectories = excludedDirs
            }
            .store(in: &cancellables)
    }

    func addExcludedDirectory(_ directory: String) {
        var excludedDirectories = settingsService.excludedOutputDirectories.currentValue
        excludedDirectories.append(directory)
        settingsService.setExcludedOutputDirectories(excludedDirectories)
    }
}
