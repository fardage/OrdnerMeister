//
//  DirectoryConfigView.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 14.01.2024.
//

import OSLog
import SwiftUI

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

#Preview {
    DirectoryConfigView(
        path: .constant("Path"),
        label: "Label",
        description: "Description"
    )
}
