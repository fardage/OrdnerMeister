//
//  ConfigurationView.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 29.12.2023.
//

import OSLog
import SwiftUI

struct ConfigurationView: View {
    @Bindable var viewModel: ConfigurationViewModel

    var body: some View {
        NavigationStack {
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
                Button {
                    viewModel.processFolders()
                } label: {
                    Text("Run")
                }
            }
            .padding()
        }
    }
}

#Preview {
    ConfigurationView(viewModel: .init())
}

struct DirectoryConfigView: View {
    @State private var isPresentedFileImporter = false
    @Binding var path: String
    let label: String
    let description: String

    var body: some View {
        Section(content: {
            TextField(
                text: $path,
                label: { Text(label) }
            )
        }, footer: {
            HStack {
                Text(description)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    isPresentedFileImporter = true
                } label: {
                    Text("Choose Directory")
                }
            }
        })
        .fileImporter(
            isPresented: $isPresentedFileImporter,
            allowedContentTypes: [.directory],
            onCompletion: { result in
                switch result {
                case let .success(directory):
                    path = directory.absoluteString
                case let .failure(error):
                    Logger.view.error("\(error)")
                }
            }
        )
    }
}
