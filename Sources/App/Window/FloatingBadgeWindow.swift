import Cocoa
import SwiftUI

@MainActor
protocol FloatingBadgeWindowDelegate: AnyObject {
    func floatingBadgeWindowDidAutoHide(_ window: FloatingBadgeWindow)
}

@MainActor
class FloatingBadgeWindow: NSWindow {
    weak var badgeDelegate: FloatingBadgeWindowDelegate?
    private var autoHideTimer: Timer?
    
    init() {
        // Create window without title bar, always on top
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 100),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
    }
    
    private func setupWindow() {
        // Window properties
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.level = .floating
        self.ignoresMouseEvents = false
        
        // Position in bottom-right corner with padding
        positionWindow()
    }
    
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
    
    private func positionWindow() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowSize = self.frame.size
        let padding: CGFloat = 20
        
        let x = screenFrame.maxX - windowSize.width - padding
        let y = screenFrame.minY + padding
        
        self.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    func showWithAnimation() {
        // Ensure we start fresh
        stopAutoHideTimer()
        self.alphaValue = 0
        self.orderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1.0
        } completionHandler: {
            // Start auto-hide timer after animation completes
            self.startAutoHideTimer()
        }
    }
    
    func hideWithAnimation() {
        print("🔍 FloatingBadgeWindow: hideWithAnimation called")
        stopAutoHideTimer()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0.0
        } completionHandler: {
            print("🔍 FloatingBadgeWindow: hide animation completed")
            self.orderOut(nil)
        }
    }
    
    private func startAutoHideTimer() {
        stopAutoHideTimer()
        print("🔍 FloatingBadgeWindow: starting auto-hide timer (5 seconds)")
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                print("🔍 FloatingBadgeWindow: auto-hide timer fired")
                guard let self = self, self.isVisible else { 
                    print("🔍 FloatingBadgeWindow: window not visible, skipping auto-hide")
                    return 
                }
                print("🔍 FloatingBadgeWindow: triggering auto-hide")
                self.hideWithAnimation()
                self.badgeDelegate?.floatingBadgeWindowDidAutoHide(self)
            }
        }
    }
    
    private func stopAutoHideTimer() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }
    
    // Reset timer when user interacts with the badge
    func resetAutoHideTimer() {
        if isVisible {
            startAutoHideTimer()
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        stopAutoHideTimer()
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        startAutoHideTimer()
    }
} 
