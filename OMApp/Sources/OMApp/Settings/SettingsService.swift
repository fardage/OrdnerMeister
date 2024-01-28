//
//  SettingsService.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 14.01.2024.
//

import Combine
import Foundation

public class SettingsService {
    private var settingsStore: SettingsStoring
    private let _inboxDirectory: CurrentValueSubject<String?, Never>
    private let _outputDirectory: CurrentValueSubject<String?, Never>
    private let _excludedOutputDirectories: CurrentValueSubject<[String], Never>

    var inboxDirectory: DomainProperty<String?> {
        _inboxDirectory.domainProperty()
    }

    var outputDirectory: DomainProperty<String?> {
        _outputDirectory.domainProperty()
    }

    var excludedOutputDirectories: DomainProperty<[String]> {
        _excludedOutputDirectories.domainProperty()
    }

    public init(settingsStore: SettingsStoring = SettingsDefaults()) {
        self.settingsStore = settingsStore
        _inboxDirectory = .init(settingsStore.inboxDirectory)
        _outputDirectory = .init(settingsStore.outputDirectory)
        _excludedOutputDirectories = .init(settingsStore.excludedOutputDirectories)
    }

    func setInboxDirectory(_ directory: String?) {
        settingsStore.inboxDirectory = directory
        _inboxDirectory.value = directory
    }

    func setOutputDirectory(_ directory: String?) {
        settingsStore.outputDirectory = directory
        _outputDirectory.value = directory
    }

    func setExcludedOutputDirectories(_ directories: [String]) {
        settingsStore.excludedOutputDirectories = directories
        _excludedOutputDirectories.value = directories
    }
}

public protocol SettingsStoring {
    var inboxDirectory: String? { get set }
    var outputDirectory: String? { get set }
    var excludedOutputDirectories: [String] { get set }
}

public struct SettingsDefaults: SettingsStoring {
    private enum SettingsDefaultsKey: String {
        case inboxDirectory
        case outputDirectory
        case excludedOutputDirectory
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .init()) {
        self.defaults = defaults
    }

    public var inboxDirectory: String? {
        get {
            defaults.string(forKey: SettingsDefaultsKey.inboxDirectory.rawValue)
        }
        set {
            defaults.setValue(newValue, forKey: SettingsDefaultsKey.inboxDirectory.rawValue)
        }
    }

    public var outputDirectory: String? {
        get {
            defaults.string(forKey: SettingsDefaultsKey.outputDirectory.rawValue)
        }
        set {
            defaults.setValue(newValue, forKey: SettingsDefaultsKey.outputDirectory.rawValue)
        }
    }

    public var excludedOutputDirectories: [String] {
        get {
            defaults.array(forKey: SettingsDefaultsKey.excludedOutputDirectory.rawValue) as? [String] ?? [String]()
        }
        set {
            defaults.setValue(newValue, forKey: SettingsDefaultsKey.excludedOutputDirectory.rawValue)
        }
    }
}
