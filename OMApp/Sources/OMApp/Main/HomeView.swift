//
//  HomeView.swift
//  OrdnerMeister
//
//  Created by Marvin Tseng on 29.12.2023.
//

import OSLog
import SwiftUI

public struct HomeView: View {
    @Bindable var viewModel: HomeViewModel

    public init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            VStack {
                StatusBar(
                    statusText: viewModel.currentStatus.description,
                    isPresentingBusy: viewModel.isBusy,
                    start: viewModel.processFolders
                )

                ActionableFilesView(
                    actionableFiles: viewModel.actionableFiles,
                    onPredictionClick: { file, folder in
                        viewModel.onPredictionClick(fileURL: file, targetFolderURL: folder)
                    }
                )
            }
            .padding()
        }
        .alert(viewModel.lastErrorMessage, isPresented: $viewModel.showingAlert) {
            Button("OK") {}
        }
    }
}

#Preview {
    HomeView(viewModel: .init(
        fileOrchestrator: FileOrchestrator(settingsService: .init())
    ))
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
            Spacer()
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

struct StatusBar: View {
    var statusText: String
    let isPresentingBusy: Bool
    let start: () -> Void

    var body: some View {
        ZStack {
            HStack {
                Button {
                    start()
                } label: {
                    Image(systemName: "play.fill")
                }
                .disabled(isPresentingBusy)

                Spacer()
            }

            HStack {
                Text(statusText)
                    .padding(.leading, 16)

                Spacer()

                if isPresentingBusy {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.trailing, 16)
                }
            }
            .frame(maxWidth: 400, maxHeight: 24)
            .background(.separator)
            .cornerRadius(4)
        }
    }
}
