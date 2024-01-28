//
//  OrdnerMeisterApp.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 29.12.2023.
//

import OMApp
import SwiftUI

@main
struct OrdnerMeisterApp: App {
    let settingsService = SettingsService()

    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: .init(
                fileOrchestrator: FileOrchestrator(settingsService: settingsService)
            ))
        }

        Settings {
            SettingsView(viewModel: .init(settingsService: settingsService))
        }
    }
}
