import SwiftUI
import PDFKit
import AppKit

/// SwiftUI view that displays a PDF preview using PDFKit
struct PDFPreviewView: View {
    let fileURL: URL
    @State private var isLoading = true
    @State private var loadError: Error?

    var body: some View {
        ZStack {
            if isLoading {
                VStack {
                    ProgressView()
                        .controlSize(.large)
                    Text("Loading preview...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
            } else if let error = loadError {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text("Failed to load PDF")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                PDFKitView(url: fileURL, isLoading: $isLoading, error: $loadError)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isLoading = true
        }
    }
}

/// NSViewRepresentable wrapper for PDFKit's PDFView
struct PDFKitView: NSViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var error: Error?

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()

        // Configure for optimal preview performance
        pdfView.displayMode = .singlePage
        pdfView.autoScales = true
        pdfView.displayDirection = .vertical
        pdfView.displaysPageBreaks = true
        pdfView.backgroundColor = NSColor.controlBackgroundColor

        // Disable navigation chrome for cleaner look
        pdfView.displaysAsBook = false

        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        // Load PDF document asynchronously
        DispatchQueue.global(qos: .userInitiated).async {
            guard let document = PDFDocument(url: url) else {
                DispatchQueue.main.async {
                    self.error = NSError(
                        domain: "PDFPreview",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unable to open PDF file"]
                    )
                    self.isLoading = false
                }
                return
            }

            DispatchQueue.main.async {
                pdfView.document = document

                // Go to first page
                if let firstPage = document.page(at: 0) {
                    pdfView.go(to: firstPage)
                }

                self.isLoading = false
                self.error = nil
            }
        }
    }
}
