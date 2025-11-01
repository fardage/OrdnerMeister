import SwiftUI

/// View for resolving file name conflicts when moving files
struct ConflictResolutionView: View {
    let existingFileName: String
    let onRename: (String) -> Void
    let onCancel: () -> Void

    @State private var newFileName: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)

                Text("File Already Exists")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding(.top, 20)

            // Message
            VStack(spacing: 12) {
                Text("A file named:")
                    .foregroundStyle(.secondary)

                Text(existingFileName)
                    .font(.body)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)

                Text("already exists at the destination.")
                    .foregroundStyle(.secondary)

                Text("Enter a new name to continue, or cancel the operation.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            // New name input
            VStack(alignment: .leading, spacing: 8) {
                Text("New file name:")
                    .font(.callout)
                    .fontWeight(.medium)

                TextField("Enter new file name", text: $newFileName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        if isValidFileName {
                            onRename(newFileName)
                        }
                    }

                if !newFileName.isEmpty && !isValidFileName {
                    Text("Please enter a valid file name with an extension")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 20)

            // Actions
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Rename and Move") {
                    onRename(newFileName)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValidFileName)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.bottom, 20)
        }
        .frame(width: 450)
        .onAppear {
            // Pre-fill with existing name and select just the base name
            newFileName = existingFileName
            isTextFieldFocused = true
        }
    }

    private var isValidFileName: Bool {
        !newFileName.isEmpty &&
        !newFileName.trimmingCharacters(in: .whitespaces).isEmpty &&
        newFileName.contains(".")
    }
}

#Preview {
    ConflictResolutionView(
        existingFileName: "document.pdf",
        onRename: { newName in
            print("Rename to: \(newName)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}
