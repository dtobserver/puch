import SwiftUI
import UniformTypeIdentifiers

struct HistoryView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var captureHistory: [CaptureItem] = []
    @State private var selectedItems: Set<UUID> = []
    @State private var searchText = ""
    
    var filteredHistory: [CaptureItem] {
        if searchText.isEmpty {
            return captureHistory
        } else {
            return captureHistory.filter { item in
                item.filename.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with filters
            VStack(alignment: .leading, spacing: 16) {
                Text("Filters")
                    .font(.headline)
                    .padding(.horizontal)
                
                List {
                    Label("All Items", systemImage: "doc.on.doc")
                    Label("Screenshots", systemImage: "photo")
                    Label("Recordings", systemImage: "video")
                }
                .listStyle(.sidebar)
                
                Spacer()
            }
            .frame(minWidth: 180)
        } detail: {
            // Main content area
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search captures...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(.regularMaterial)
                
                Divider()
                
                // Content area
                if filteredHistory.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                        
                        VStack(spacing: 8) {
                            Text("No Captures Yet")
                                .font(.headline)
                            
                            Text("Your screenshots and recordings will appear here")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button("Take Screenshot") {
                            viewModel.takeScreenshot()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Grid view of captures
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 200, maximum: 250), spacing: 16)
                        ], spacing: 16) {
                            ForEach(filteredHistory) { item in
                                CaptureItemView(
                                    item: item,
                                    isSelected: selectedItems.contains(item.id)
                                ) {
                                    // Toggle selection
                                    if selectedItems.contains(item.id) {
                                        selectedItems.remove(item.id)
                                    } else {
                                        selectedItems.insert(item.id)
                                    }
                                } onOpen: {
                                    NSWorkspace.shared.open(item.url)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Capture History")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if !selectedItems.isEmpty {
                    Button("Delete Selected") {
                        deleteSelectedItems()
                    }
                    .foregroundStyle(.red)
                }
                
                Button("Clear All") {
                    clearAllHistory()
                }
                .disabled(captureHistory.isEmpty)
            }
        }
        .onAppear {
            loadCaptureHistory()
        }
        .onChange(of: viewModel.lastScreenshotURL) { _ in
            loadCaptureHistory()
        }
        .onChange(of: viewModel.lastRecordingURL) { _ in
            loadCaptureHistory()
        }
    }
    
    private func loadCaptureHistory() {
        // In a real app, this would load from persistent storage
        var items: [CaptureItem] = []
        
        if let screenshot = viewModel.lastScreenshotURL {
            items.append(CaptureItem(
                id: UUID(),
                url: screenshot,
                filename: screenshot.lastPathComponent,
                type: .screenshot,
                date: Date(),
                fileSize: getFileSize(url: screenshot)
            ))
        }
        
        if let recording = viewModel.lastRecordingURL {
            items.append(CaptureItem(
                id: UUID(),
                url: recording,
                filename: recording.lastPathComponent,
                type: .recording,
                date: Date(),
                fileSize: getFileSize(url: recording)
            ))
        }
        
        captureHistory = items.sorted { $0.date > $1.date }
    }
    
    private func getFileSize(url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    private func deleteSelectedItems() {
        let itemsToDelete = captureHistory.filter { selectedItems.contains($0.id) }
        
        for item in itemsToDelete {
            do {
                try FileManager.default.removeItem(at: item.url)
            } catch {
                print("Failed to delete file: \(error)")
            }
        }
        
        captureHistory.removeAll { selectedItems.contains($0.id) }
        selectedItems.removeAll()
    }
    
    private func clearAllHistory() {
        for item in captureHistory {
            do {
                try FileManager.default.removeItem(at: item.url)
            } catch {
                print("Failed to delete file: \(error)")
            }
        }
        captureHistory.removeAll()
        selectedItems.removeAll()
    }
}

struct CaptureItem: Identifiable {
    let id: UUID
    let url: URL
    let filename: String
    let type: CaptureType
    let date: Date
    let fileSize: Int64
    
    enum CaptureType {
        case screenshot
        case recording
        
        var icon: String {
            switch self {
            case .screenshot: return "photo.fill"
            case .recording: return "video.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .screenshot: return .green
            case .recording: return .blue
            }
        }
    }
}

struct CaptureItemView: View {
    let item: CaptureItem
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onOpen: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail/Preview area
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary)
                .frame(height: 120)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: item.type.icon)
                            .font(.system(size: 32))
                            .foregroundStyle(item.type.color)
                        
                        Text(item.type == .screenshot ? "Screenshot" : "Recording")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    Button(action: onToggleSelection) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(isSelected ? .blue : .secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                }
            
            // File info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.filename)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                HStack {
                    Text(formatDate(item.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(formatFileSize(item.fileSize))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? .blue : .clear, lineWidth: 2)
        )
        .onTapGesture(count: 2) {
            onOpen()
        }
        .onTapGesture {
            onToggleSelection()
        }
        .contextMenu {
            Button("Open") {
                onOpen()
            }
            
            Button("Show in Finder") {
                NSWorkspace.shared.selectFile(item.url.path, inFileViewerRootedAtPath: "")
            }
            
            Divider()
            
            Button("Delete", role: .destructive) {
                // Delete action
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
} 