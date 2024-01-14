//
//  SettingsView.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 14.01.2024.
//

import SwiftUI

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general
    }

    var body: some View {
        TabView {
            FolderSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
        }
        .padding(20)
        .frame(width: 750, height: 300)
    }
}

struct FolderSettingsView: View {
    @Bindable var viewModel = FolderSettingsViewModel()

    var body: some View {
        Form {
            DirectoryConfigView(
                path: $viewModel.inboxDirectory,
                label: "Inbox",
                description: "Directory with input files to be classified and sorted"
            )
            DirectoryConfigView(
                path: $viewModel.outputDirectory,
                label: "Output",
                description: "Directory where the input files should be moved to and sorted"
            )
        }
    }
}

#Preview {
    SettingsView()
}
