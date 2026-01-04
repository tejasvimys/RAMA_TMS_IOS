//
//  PDFViewerView.swift
//  RAMA_TMS
//
//  Created by Tejasvi Mahesh on 1/4/26.
//  Created for PDF receipt viewing
//

import SwiftUI
import PDFKit

struct PDFViewerView: View {
    let receiptId: Int64
    let donorName: String
    
    @State private var pdfData: Data?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showShareSheet = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            RamaTheme.background.ignoresSafeArea()
            
            if isLoading {
                loadingView
            } else if let error = errorMessage {
                errorView(error)
            } else if let data = pdfData {
                PDFKitView(data: data)
            } else {
                emptyView
            }
        }
        .navigationTitle("Receipt")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if pdfData != nil {
                    Button(action: { showShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(RamaTheme.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = pdfData {
                ShareSheet(items: [createPDFFile(data: data)])
            }
        }
        .task {
            await loadPDF()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(RamaTheme.primary)
            
            Text("Loading receipt...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Failed to Load Receipt")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                Task { await loadPDF() }
            }) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(RamaTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Receipt Available")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Load PDF
    private func loadPDF() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let data = try await QuickDonationApi.shared.downloadReceiptPdf(receiptId: receiptId)
            
            await MainActor.run {
                self.pdfData = data
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Create PDF File for Sharing
    private func createPDFFile(data: Data) -> URL {
        let fileName = "Receipt-\(donorName)-\(receiptId).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try? data.write(to: tempURL)
        
        return tempURL
    }
}

// MARK: - PDFKit View Wrapper
struct PDFKitView: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let document = PDFDocument(data: data) {
            pdfView.document = document
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
struct PDFViewerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PDFViewerView(receiptId: 123, donorName: "John Doe")
        }
    }
}

