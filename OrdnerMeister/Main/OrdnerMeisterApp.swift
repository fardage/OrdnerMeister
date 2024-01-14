//
//  OrdnerMeisterApp.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 29.12.2023.
//

import SwiftUI

@main
struct OrdnerMeisterApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        #if os(macOS)
            Settings {
                SettingsView()
            }
        #endif
    }
}
