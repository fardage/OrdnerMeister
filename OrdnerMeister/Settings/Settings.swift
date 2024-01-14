//
//  Settings.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 14.01.2024.
//

import Foundation

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
