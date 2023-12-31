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
                Button {
                    viewModel.showFileImporter = true
                } label: {
                    Label("Choose directory", systemImage: "folder.circle")
                }
            }
            .padding()
        }
        .fileImporter(
            isPresented: $viewModel.showFileImporter,
            allowedContentTypes: [.directory],
            onCompletion: viewModel.onOutputDirectorySelected
        )
    }
}

#Preview {
    ConfigurationView(viewModel: .init())
}
