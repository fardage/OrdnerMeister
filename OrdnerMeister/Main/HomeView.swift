//
//  HomeView.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 29.12.2023.
//

import OSLog
import SwiftUI

struct HomeView: View {
    @Bindable var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                Button {
                    viewModel.processFolders()
                } label: {
                    Text("Run")
                }

                ActionableFilesView(
                    actionableFiles: viewModel.actionableFiles,
                    onPredictionClick: { file, folder in
                        viewModel.onPredictionClick(fileURL: file, targetFolderURL: folder)
                    }
                )
            }
            .padding()
        }
    }
}

#Preview {
    HomeView(viewModel: .init())
}

struct ActionableFilesView: View {
    let actionableFiles: [FilePrediction]
    let onPredictionClick: (URL, URL) -> Void

    var body: some View {
        List(actionableFiles) { actionableFile in
            FileRowView(
                file: actionableFile.file,
                predictedOutputFolders: actionableFile.predictedOutputFolders,
                onPredictionClick: onPredictionClick
            )
        }
    }
}

struct FileRowView: View {
    let file: URL
    let predictedOutputFolders: [URL]
    let onPredictionClick: (URL, URL) -> Void

    var body: some View {
        HStack {
            Text(file.lastPathComponent)
            ForEach(predictedOutputFolders, id: \.self) { folder in
                Button {
                    onPredictionClick(file, folder)
                } label: {
                    Label(folder.lastPathComponent, systemImage: "folder.badge.plus")
                }
            }
        }
    }
}
