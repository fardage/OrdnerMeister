import OSLog
import SwiftUI

public struct SettingsView: View {
    private enum Tabs: Hashable {
        case general
    }

    @Bindable var viewModel: SettingsViewModel

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        TabView {
            FolderSettingsView(viewModel: viewModel)
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
    @Bindable var viewModel: SettingsViewModel

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

            DirList(
                description: "Directories in the output folder to exclude / ignore",
                directories: viewModel.excludedDirectories,
                addDirectory: viewModel.addExcludedDirectory,
                removeDirectory: viewModel.removeExcludedDirectory
            )
        }
        .padding()
    }
}

struct DirList: View {
    @State private var isPresentedFileImporter = false
    let description: String
    let directories: [String]
    let addDirectory: (String) -> Void
    let removeDirectory: (String) -> Void

    var body: some View {
        Section {
            List(directories, id: \.self) { dir in
                HStack {
                    Label(dir, systemImage: "folder.badge.minus")
                    Spacer()
                    Button {
                        removeDirectory(dir)
                    } label: {
                        Image(systemName: "minus.square")
                    }
                }
            }
            .border(Color(NSColor.gridColor), width: 1)
        } header: {
            Text("Ignored folders in output directory:")
        } footer: {
            HStack {
                Text(description)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    isPresentedFileImporter = true
                } label: {
                    Text("Exclude Directory")
                }
            }
        }
        .fileImporter(
            isPresented: $isPresentedFileImporter,
            allowedContentTypes: [.directory],
            onCompletion: { result in
                switch result {
                case let .success(directory):
                    addDirectory(directory.absoluteString)
                case let .failure(error):
                    Logger().error("\(error)")
                }
            }
        )
    }
}
