import Foundation
@preconcurrency import AVFoundation
@preconcurrency import ScreenCaptureKit
import CoreGraphics
import AppKit

@MainActor
protocol ScreenCaptureManagerDelegate: AnyObject {
    func screenCaptureManagerDidStartRecording(_ manager: ScreenCaptureManager)
    func screenCaptureManager(_ manager: ScreenCaptureManager, didFinishRecordingTo url: URL?)
    func screenCaptureManager(_ manager: ScreenCaptureManager, didTakeScreenshot url: URL)
    func screenCaptureManager(_ manager: ScreenCaptureManager, didFail error: Error)
}

@MainActor
enum ScreenshotMode {
    case fullScreen
    case window
    case area
}

@MainActor
class ScreenCaptureManager: NSObject, SCStreamOutput, AudioCaptureManagerDelegate, @unchecked Sendable {
    weak var delegate: ScreenCaptureManagerDelegate?

    var windowBackground: PersistenceManager.Settings.WindowScreenshotBackground = .wallpaper
    var screenshotScale: CGFloat = 1.0
    var outputDirectory: URL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory

    private var stream: SCStream?
    private var writer: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var audioManager: AudioCaptureManager?
    private let queue = DispatchQueue(label: "ScreenCaptureQueue")

    private func resizedImage(from image: NSImage) -> NSImage {
        guard screenshotScale < 1.0 else { return image }
        let newSize = NSSize(width: image.size.width * screenshotScale, height: image.size.height * screenshotScale)
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }

    private func resizeImageAtURL(_ url: URL) {
        guard screenshotScale < 1.0, let image = NSImage(contentsOf: url) else { return }
        let scaled = resizedImage(from: image)
        if let tiff = scaled.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let data = rep.representation(using: .png, properties: [:]) {
            try? data.write(to: url)
        }
    }

    func startRecording(withAudio: Bool = false) {
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                guard let display = content.displays.first else { return }
                let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
                let configuration = SCStreamConfiguration()
                configuration.width = display.width
                configuration.height = display.height
                configuration.queueDepth = 5
                configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)

                let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
                try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: queue)
                self.stream = stream

                let url = outputDirectory.appendingPathComponent("Recording_\(Date().timeIntervalSince1970).mov")
                let writer = try AVAssetWriter(url: url, fileType: .mov)
                let input = AVAssetWriterInput(mediaType: .video, outputSettings: [AVVideoCodecKey: AVVideoCodecType.h264])
                input.expectsMediaDataInRealTime = true
                writer.add(input)
                self.writer = writer
                self.videoInput = input

                if withAudio {
                    let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
                    audioInput.expectsMediaDataInRealTime = true
                    if writer.canAdd(audioInput) {
                        writer.add(audioInput)
                        self.audioInput = audioInput
                        let audioManager = AudioCaptureManager()
                        audioManager.delegate = self
                        self.audioManager = audioManager
                        audioManager.startCapturing()
                    }
                }

                writer.startWriting()
                writer.startSession(atSourceTime: .zero)
                try await stream.startCapture()
                self.delegate?.screenCaptureManagerDidStartRecording(self)
            } catch {
                self.delegate?.screenCaptureManager(self, didFail: error)
            }
        }
    }

    func stopRecording() {
        guard let stream = self.stream else { return }
        
        Task {
            do {
                try await stream.stopCapture()
                videoInput?.markAsFinished()
                audioInput?.markAsFinished()
                
                let writer = self.writer
                await withCheckedContinuation { continuation in
                    writer?.finishWriting {
                        let url = writer?.outputURL
                        Task { @MainActor in
                            self.stream = nil
                            self.writer = nil
                            self.videoInput = nil
                            self.audioInput = nil
                            self.delegate?.screenCaptureManager(self, didFinishRecordingTo: url)
                            continuation.resume()
                        }
                    }
                }
            } catch {
                self.delegate?.screenCaptureManager(self, didFail: error)
            }
            
            self.audioManager?.stopCapturing()
            self.audioManager = nil
        }
    }

    func takeScreenshot(mode: ScreenshotMode = .fullScreen) {
        if #available(macOS 15.2, *) {
            Task {
                do {
                    let url = outputDirectory.appendingPathComponent("Screenshot_\(Date().timeIntervalSince1970).png")
                    switch mode {
                    case .fullScreen:
                        let screenRect = CGRect(x: 0, y: 0, width: CGDisplayPixelsWide(CGMainDisplayID()), height: CGDisplayPixelsHigh(CGMainDisplayID()))
                        let cgImage = try await SCScreenshotManager.captureImage(in: screenRect)
                        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                        let finalImage = resizedImage(from: nsImage)
                        if let tiff = finalImage.tiffRepresentation,
                           let rep = NSBitmapImageRep(data: tiff),
                           let data = rep.representation(using: .png, properties: [:]) {
                            try data.write(to: url)
                            self.delegate?.screenCaptureManager(self, didTakeScreenshot: url)
                        }
                    case .area:
                        let process = Process()
                        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
                        process.arguments = ["-s", "-x", url.path]
                        try process.run()
                        process.waitUntilExit()
                        if process.terminationStatus == 0 {
                            resizeImageAtURL(url)
                            self.delegate?.screenCaptureManager(self, didTakeScreenshot: url)
                        } else {
                            self.delegate?.screenCaptureManager(self, didFail: NSError(domain: "ScreenCapture", code: Int(process.terminationStatus), userInfo: nil))
                        }
                    case .window:
                        let process = Process()
                        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
                        process.arguments = ["-w", "-x", url.path]
                        try process.run()
                        process.waitUntilExit()
                        if process.terminationStatus == 0 {
                            self.handleWindowBackground(at: url)
                        } else {
                            self.delegate?.screenCaptureManager(self, didFail: NSError(domain: "ScreenCapture", code: Int(process.terminationStatus), userInfo: nil))
                        }
                    }
                } catch {
                    self.delegate?.screenCaptureManager(self, didFail: error)
                }
            }
        } else {
            // Fallback for older macOS versions - use alternative screenshot method
            Task {
                do {
                    let url = outputDirectory.appendingPathComponent("Screenshot_\(Date().timeIntervalSince1970).png")
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
                    switch mode {
                    case .area:
                        process.arguments = ["-s", "-x", url.path]
                    case .window:
                        process.arguments = ["-w", "-x", url.path]
                    case .fullScreen:
                        process.arguments = ["-x", url.path]
                    }
                    try process.run()
                    process.waitUntilExit()
                    if process.terminationStatus == 0 {
                        if mode == .window {
                            self.handleWindowBackground(at: url)
                        } else {
                            resizeImageAtURL(url)
                            self.delegate?.screenCaptureManager(self, didTakeScreenshot: url)
                        }
                    } else {
                        self.delegate?.screenCaptureManager(self, didFail: NSError(domain: "ScreenCapture", code: Int(process.terminationStatus), userInfo: nil))
                    }
                } catch {
                    self.delegate?.screenCaptureManager(self, didFail: error)
                }
            }
        }
    }

    private func handleWindowBackground(at url: URL) {
        guard let image = NSImage(contentsOf: url) else {
            self.delegate?.screenCaptureManager(self, didTakeScreenshot: url)
            return
        }

        // Get settings for padding and increase it for more wallpaper visibility
        let settings = PersistenceManager.shared.loadSettings() ?? .default
        let padding = CGFloat(settings.windowPadding * 5)
        
        // Calculate new size with padding
        let originalSize = image.size
        let newSize = NSSize(width: originalSize.width + (padding * 2), 
                            height: originalSize.height + (padding * 2))
        
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()

        switch windowBackground {
        case .white:
            NSColor.white.setFill()
            NSBezierPath(rect: NSRect(origin: .zero, size: newSize)).fill()
        case .gradient:
            let gradient = NSGradient(colors: [NSColor(calibratedWhite: 0.95, alpha: 1.0), NSColor(calibratedWhite: 0.75, alpha: 1.0)])
            gradient?.draw(in: NSRect(origin: .zero, size: newSize), angle: 90)
        case .wallpaper:
            // Get current wallpaper and draw it as background
            if let wallpaperImage = getCurrentWallpaper() {
                let wallpaperSize = wallpaperImage.size
                let targetSize = newSize
                
                // Calculate scale to fill the target size while maintaining aspect ratio
                let scaleX = targetSize.width / wallpaperSize.width
                let scaleY = targetSize.height / wallpaperSize.height
                let scale = max(scaleX, scaleY)
                
                let scaledWidth = wallpaperSize.width * scale
                let scaledHeight = wallpaperSize.height * scale
                
                // Center the scaled wallpaper
                let x = (targetSize.width - scaledWidth) / 2
                let y = (targetSize.height - scaledHeight) / 2
                
                let sourceRect = NSRect(origin: .zero, size: wallpaperSize)
                let destRect = NSRect(x: x, y: y, width: scaledWidth, height: scaledHeight)
                
                wallpaperImage.draw(in: destRect, 
                                  from: sourceRect, 
                                  operation: .copy, 
                                  fraction: 1.0)
            } else {
                // Fallback to white background if wallpaper can't be loaded
                NSColor.white.setFill()
                NSBezierPath(rect: NSRect(origin: .zero, size: newSize)).fill()
            }
        }

        // Draw the original window screenshot centered with padding
        let imageRect = NSRect(x: padding, y: padding, 
                              width: originalSize.width, height: originalSize.height)
        image.draw(in: imageRect, 
                  from: NSRect(origin: .zero, size: originalSize), 
                  operation: .sourceOver, 
                  fraction: 1.0)
        
        newImage.unlockFocus()

        let finalImage = resizedImage(from: newImage)

        if let tiff = finalImage.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let data = rep.representation(using: .png, properties: [:]) {
            try? data.write(to: url)
        }

        self.delegate?.screenCaptureManager(self, didTakeScreenshot: url)
    }
    
    private func getCurrentWallpaper() -> NSImage? {
        guard let screen = NSScreen.main else { return nil }
        
        // First try the NSWorkspace approach
        if let imageURL = NSWorkspace.shared.desktopImageURL(for: screen) {
            if let wallpaperImage = NSImage(contentsOf: imageURL) {
                return wallpaperImage
            }
        }
        
        // Fallback: Try to capture the actual desktop behind all windows
        let screenRect = screen.frame
        let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? CGMainDisplayID()
        
        if let cgImage = CGDisplayCreateImage(displayID) {
            let nsImage = NSImage(cgImage: cgImage, size: screenRect.size)
            return nsImage
        }
        
        return nil
    }

    // MARK: - SCStreamOutput
    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard outputType == .screen else { return }
        // CMSampleBuffer is thread-safe, so we can safely pass it across actor boundaries
        Task { @MainActor [sampleBuffer] in
            guard let input = self.videoInput, input.isReadyForMoreMediaData else { return }
            input.append(sampleBuffer)
        }
    }

    // MARK: - AudioCaptureManagerDelegate
    nonisolated func audioCaptureManager(_ manager: AudioCaptureManager, didOutput sampleBuffer: CMSampleBuffer) {
        // CMSampleBuffer is thread-safe, so we can safely pass it across actor boundaries
        Task { @MainActor [sampleBuffer] in
            guard let input = self.audioInput, input.isReadyForMoreMediaData else { return }
            input.append(sampleBuffer)
        }
    }

    nonisolated func audioCaptureManager(_ manager: AudioCaptureManager, didFail error: Error) {
        Task { @MainActor in
            self.delegate?.screenCaptureManager(self, didFail: error)
        }
    }
}
