import Foundation
import SwiftUI
import AppKit

@MainActor
class FloatingBadgeManager: ObservableObject, FloatingBadgeWindowDelegate {
    @Published var isVisible = false
    
    private var badgeWindow: FloatingBadgeWindow?
    private var previewWindow: NSWindow?
    private var currentScreenshotURL: URL?
    
    func showBadge(for screenshotURL: URL) {
        print("🔍 showBadge called for: \(screenshotURL.lastPathComponent)")
        
        // Always dismiss current badge first to ensure clean state
        if isVisible {
            print("🔍 Dismissing current badge first")
            dismissCurrentBadge()
        }
        
        // Show new badge immediately
        currentScreenshotURL = screenshotURL
        showBadgeWindow()
    }
    
    private func showBadgeWindow() {
        guard let screenshotURL = currentScreenshotURL else { return }
        
        print("🔍 showBadgeWindow for: \(screenshotURL.lastPathComponent)")
        
        // Clean up any existing badge
        badgeWindow?.orderOut(nil)
        badgeWindow = nil
        
        // Create fresh badge window
        badgeWindow = FloatingBadgeWindow()
        badgeWindow?.badgeDelegate = self
        guard let window = badgeWindow else { return }
        
        // Create the SwiftUI view
        let badgeView = FloatingBadgeView(
            screenshotURL: screenshotURL,
            onPreview: { [weak self] in
                self?.showPreview()
            },
            onCopy: { [weak self] in
                self?.copyToClipboard()
            },
            onDismiss: { [weak self] in
                self?.dismissCurrentBadge()
            }
        )
        
        // Set up the hosting view
        let hostingView = NSHostingView(rootView: badgeView)
        window.contentView = hostingView
        
        // Show with animation
        window.showWithAnimation()
        isVisible = true
        print("🔍 Badge window shown, isVisible=true")
    }
    
    private func dismissCurrentBadge() {
        print("🔍 dismissCurrentBadge called, isVisible=\(isVisible)")
        
        badgeWindow?.hideWithAnimation()
        badgeWindow = nil
        isVisible = false
        currentScreenshotURL = nil
        
        print("🔍 Badge dismissed, isVisible=false")
    }
    
    private func showPreview() {
        guard let screenshotURL = currentScreenshotURL else { return }
        
        // Reset auto-hide timer
        badgeWindow?.resetAutoHideTimer()
        
        // Close existing preview window first
        closePreview()
        
        // Create new preview window
        let previewView = ScreenshotPreviewView(
            screenshotURL: screenshotURL,
            onClose: { [weak self] in
                self?.closePreview()
            }
        )
            
        let hostingView = NSHostingView(rootView: previewView)
        
        previewWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        previewWindow?.title = "Screenshot Preview"
        previewWindow?.contentView = hostingView
        previewWindow?.center()
        previewWindow?.setFrameAutosaveName("ScreenshotPreview")
        previewWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func closePreview() {
        previewWindow?.orderOut(nil)
        previewWindow = nil
    }
    
    private func copyToClipboard() {
        guard let screenshotURL = currentScreenshotURL else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // Copy both file URL and image data
        pasteboard.writeObjects([screenshotURL as NSURL])
        
        if let image = NSImage(contentsOf: screenshotURL) {
            pasteboard.writeObjects([image])
        }
        
        // Provide visual feedback
        showCopyFeedback()
        
        // Dismiss after copying
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.dismissCurrentBadge()
        }
    }
    
    private func showCopyFeedback() {
        // Create a temporary feedback window
        let feedbackView = Text("Copied to Clipboard")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 8))
        
        let hostingView = NSHostingView(rootView: feedbackView)
        let feedbackWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 40),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        feedbackWindow.contentView = hostingView
        feedbackWindow.backgroundColor = .clear
        feedbackWindow.isOpaque = false
        feedbackWindow.level = .floating
        feedbackWindow.ignoresMouseEvents = true
        
        // Position above the badge
        if let badgeFrame = badgeWindow?.frame {
            let x = badgeFrame.midX - 100
            let y = badgeFrame.maxY + 10
            feedbackWindow.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            feedbackWindow.center()
        }
        
        // Show with fade animation
        feedbackWindow.alphaValue = 0
        feedbackWindow.orderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            feedbackWindow.animator().alphaValue = 1.0
        }
        
        // Hide after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                feedbackWindow.animator().alphaValue = 0.0
            } completionHandler: {
                feedbackWindow.orderOut(nil)
            }
        }
    }
    
    func hideAllBadges() {
        if isVisible {
            dismissCurrentBadge()
        }
        closePreview()
    }
    
    // MARK: - FloatingBadgeWindowDelegate
    func floatingBadgeWindowDidAutoHide(_ window: FloatingBadgeWindow) {
        print("🔍 FloatingBadgeManager: received auto-hide notification")
        dismissCurrentBadge()
    }
    

} 