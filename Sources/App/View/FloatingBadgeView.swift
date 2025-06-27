import SwiftUI
import UniformTypeIdentifiers

struct FloatingBadgeView: View {
    let screenshotURL: URL
    let onPreview: () -> Void
    let onCopy: () -> Void
    let onDismiss: () -> Void
    
    @State private var thumbnailImage: NSImage?
    @State private var isDragging = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail preview
            Group {
                if let thumbnail = thumbnailImage {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.6)
                        )
                }
            }
            .onDrag {
                createDragItem()
            }
            .scaleEffect(isDragging ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
            
            // Action buttons
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ActionButton(
                        icon: "eye.fill",
                        action: onPreview,
                        tooltip: "Preview"
                    )
                    
                    ActionButton(
                        icon: "doc.on.doc.fill",
                        action: onCopy,
                        tooltip: "Copy"
                    )
                    
                    ActionButton(
                        icon: "xmark",
                        action: onDismiss,
                        tooltip: "Dismiss"
                    )
                }
                
                Text("Screenshot captured")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        Task {
            if let image = NSImage(contentsOf: screenshotURL) {
                // Create thumbnail
                let thumbnail = createThumbnail(from: image, size: CGSize(width: 120, height: 120))
                await MainActor.run {
                    self.thumbnailImage = thumbnail
                }
            }
        }
    }
    
    private func createThumbnail(from image: NSImage, size: CGSize) -> NSImage {
        let thumbnail = NSImage(size: size)
        thumbnail.lockFocus()
        
        let imageSize = image.size
        let aspectRatio = imageSize.width / imageSize.height
        let thumbnailAspectRatio = size.width / size.height
        
        var drawRect: NSRect
        if aspectRatio > thumbnailAspectRatio {
            // Image is wider
            let height = size.height
            let width = height * aspectRatio
            let x = (size.width - width) / 2
            drawRect = NSRect(x: x, y: 0, width: width, height: height)
        } else {
            // Image is taller or square
            let width = size.width
            let height = width / aspectRatio
            let y = (size.height - height) / 2
            drawRect = NSRect(x: 0, y: y, width: width, height: height)
        }
        
        image.draw(in: drawRect)
        thumbnail.unlockFocus()
        
        return thumbnail
    }
    
    private func createDragItem() -> NSItemProvider {
        let provider = NSItemProvider()
        
        // Add file URL
        provider.registerFileRepresentation(
            forTypeIdentifier: UTType.png.identifier,
            fileOptions: .init(),
            visibility: .all
        ) { completion in
            completion(self.screenshotURL, true, nil)
            return nil
        }
        
        // Add image data
        if let imageData = try? Data(contentsOf: screenshotURL) {
            provider.registerDataRepresentation(
                forTypeIdentifier: UTType.png.identifier,
                visibility: .all
            ) { completion in
                completion(imageData, nil)
                return nil
            }
        }
        
        return provider
    }
}

struct ActionButton: View {
    let icon: String
    let action: () -> Void
    let tooltip: String
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 24, height: 24)
                                 .background(
                     Circle()
                         .fill(isHovered ? Color.primary.opacity(0.1) : Color.clear)
                 )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .help(tooltip)
    }
}

struct FloatingBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        FloatingBadgeView(
            screenshotURL: URL(fileURLWithPath: "/tmp/test.png"),
            onPreview: {},
            onCopy: {},
            onDismiss: {}
        )
        .frame(width: 280, height: 100)
    }
} 