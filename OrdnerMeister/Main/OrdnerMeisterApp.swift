//
//  OrdnerMeisterApp.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 29.12.2023.
//

import SwiftUI
import OrdnerMeisterPresentation

@main
struct OrdnerMeisterApp: App {
    let dependencies = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: dependencies.makeHomeViewModel())
        }

        Settings {
            SettingsView(viewModel: dependencies.makeSettingsViewModel())
        }
    }
}
