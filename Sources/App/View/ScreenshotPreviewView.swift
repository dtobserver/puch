import SwiftUI
import UniformTypeIdentifiers

struct ScreenshotPreviewView: View {
    let screenshotURL: URL
    let onClose: () -> Void
    
    @State private var image: NSImage?
    @State private var imageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var showingSharing = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.opacity(0.05)
                    .ignoresSafeArea()
                
                if let image = image {
                    // Image viewer
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(imageScale)
                        .offset(imageOffset)
                        .gesture(
                            SimultaneousGesture(
                                // Drag gesture
                                DragGesture()
                                    .onChanged { value in
                                        imageOffset = value.translation
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring()) {
                                            imageOffset = .zero
                                        }
                                    },
                                
                                // Zoom gesture
                                MagnificationGesture()
                                    .onChanged { value in
                                        imageScale = value.magnitude
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring()) {
                                            imageScale = max(0.5, min(imageScale, 3.0))
                                        }
                                    }
                            )
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring()) {
                                if imageScale == 1.0 {
                                    imageScale = 2.0
                                } else {
                                    imageScale = 1.0
                                    imageOffset = .zero
                                }
                            }
                        }
                } else {
                    // Loading state
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Loading screenshot...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    // Zoom controls
                    if image != nil {
                        Button("Fit to Window") {
                            withAnimation(.spring()) {
                                imageScale = 1.0
                                imageOffset = .zero
                            }
                        }
                        .disabled(imageScale == 1.0 && imageOffset == .zero)
                        
                        Button("Actual Size") {
                            if let image = image {
                                let actualScale = min(
                                    geometry.size.width / image.size.width,
                                    geometry.size.height / image.size.height
                                )
                                withAnimation(.spring()) {
                                    imageScale = 1.0 / actualScale
                                    imageOffset = .zero
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Action buttons
                    Button("Copy") {
                        copyToClipboard()
                    }
                    
                    Button("Share") {
                        showingSharing = true
                    }
                    
                    Button("Open in Finder") {
                        NSWorkspace.shared.selectFile(screenshotURL.path, inFileViewerRootedAtPath: "")
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onClose()
                    }
                    .keyboardShortcut(.escape)
                }
            }
        }
        .navigationTitle(screenshotURL.lastPathComponent)
        .onAppear {
            loadImage()
        }
        .background(HostingWindowFinder { window in
            window?.standardWindowButton(.zoomButton)?.isHidden = false
        })
        .sheet(isPresented: $showingSharing) {
            SharingView(url: screenshotURL)
        }
    }
    
    private func loadImage() {
        Task {
            if let loadedImage = NSImage(contentsOf: screenshotURL) {
                await MainActor.run {
                    self.image = loadedImage
                }
            }
        }
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // Copy both file URL and image data
        pasteboard.writeObjects([screenshotURL as NSURL])
        
        if let image = image {
            pasteboard.writeObjects([image])
        }
        
        // Show brief confirmation
        // This could be enhanced with a toast notification
    }
}

struct SharingView: View {
    let url: URL
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Share Screenshot")
                .font(.headline)
            
            // This would typically use NSSharingServicePicker
            // For now, we'll show basic sharing options
            VStack(spacing: 12) {
                Button("Copy to Clipboard") {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.writeObjects([url as NSURL])
                    
                    if let image = NSImage(contentsOf: url) {
                        pasteboard.writeObjects([image])
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Open in Default App") {
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.bordered)
                
                Button("Show in Finder") {
                    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(20)
        .frame(width: 300)
    }
}

// Helper to find the hosting window
struct HostingWindowFinder: NSViewRepresentable {
    var callback: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.callback(view.window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // No updates needed
    }
}

struct ScreenshotPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        ScreenshotPreviewView(
            screenshotURL: URL(fileURLWithPath: "/tmp/test.png"),
            onClose: {}
        )
    }
} 
