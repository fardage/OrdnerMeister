//
//  ConfigurationView.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 29.12.2023.
//

import SwiftUI

struct ConfigurationView: View {
    @Bindable var viewModel: ConfigurationViewModel

    var body: some View {
        NavigationStack {
            Form {
                TextField(
                    text: $viewModel.inputFolder,
                    prompt: Text("~/input/folder/*.pdf"),
                    label: { Text("Input Folder:") }
                )
                TextField(
                    text: $viewModel.outputFolder,
                    prompt: Text("~/output/folder"),
                    label: { Text("Output Folder:") }
                )

                Button("Run") {
                    viewModel.processFolders()
                }
            }
            .padding()
        }
    }
}

#Preview {
    ConfigurationView(viewModel: .init())
}
