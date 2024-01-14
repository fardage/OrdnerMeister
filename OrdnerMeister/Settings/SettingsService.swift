//
//  SettingsService.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 14.01.2024.
//

import Combine
import Foundation

class SettingsService {
    private var settingsStore: SettingsStoring
    private let _inboxDirectory: CurrentValueSubject<String?, Never>
    private let _outputDirectory: CurrentValueSubject<String?, Never>

    var inboxDirectory: DomainProperty<String?> {
        _inboxDirectory.domainProperty()
    }

    var outputDirectory: DomainProperty<String?> {
        _outputDirectory.domainProperty()
    }

    init(settingsStore: SettingsStoring = SettingsDefaults()) {
        self.settingsStore = settingsStore
        _inboxDirectory = .init(settingsStore.inboxDirectory)
        _outputDirectory = .init(settingsStore.outputDirectory)
    }

    func setInboxDirectory(_ directory: String?) {
        settingsStore.inboxDirectory = directory
        _inboxDirectory.value = directory
    }

    func setOutputDirectory(_ directory: String?) {
        settingsStore.outputDirectory = directory
        _outputDirectory.value = directory
    }
}

protocol SettingsStoring {
    var inboxDirectory: String? { get set }
    var outputDirectory: String? { get set }
}

struct SettingsDefaults: SettingsStoring {
    private enum SettingsDefaultsKey: String {
        case inboxDirectory
        case outputDirectory
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .init()) {
        self.defaults = defaults
    }

    var inboxDirectory: String? {
        get {
            defaults.string(forKey: SettingsDefaultsKey.inboxDirectory.rawValue)
        }
        set {
            defaults.setValue(newValue, forKey: SettingsDefaultsKey.inboxDirectory.rawValue)
        }
    }

    var outputDirectory: String? {
        get {
            defaults.string(forKey: SettingsDefaultsKey.outputDirectory.rawValue)
        }
        set {
            defaults.setValue(newValue, forKey: SettingsDefaultsKey.outputDirectory.rawValue)
        }
    }
}
