import OSLog
import SwiftUI

public struct DirectoryConfigView: View {
    @State private var isPresentedFileImporter = false
    @Binding var path: String
    let label: String
    let description: String

    public init(path: Binding<String>, label: String, description: String) {
        self._path = path
        self.label = label
        self.description = description
    }

    public var body: some View {
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
                    Logger().error("\(error)")
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
