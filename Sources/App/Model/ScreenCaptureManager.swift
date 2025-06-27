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

class ScreenCaptureManager: NSObject, SCStreamOutput, AudioCaptureManagerDelegate {
    weak var delegate: ScreenCaptureManagerDelegate?

    var windowBackground: PersistenceManager.Settings.WindowScreenshotBackground = .desktop

    private var stream: SCStream?
    private var writer: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var audioManager: AudioCaptureManager?
    private let queue = DispatchQueue(label: "ScreenCaptureQueue")

    func startRecording(withAudio: Bool = false) {
        Task { @MainActor in
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

                let url = FileManager.default.temporaryDirectory.appendingPathComponent("Recording_\(Date().timeIntervalSince1970).mov")
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

    nonisolated func stopRecording() {
        Task { @MainActor in
            guard let stream = self.stream else { return }
            
            do {
                try await stream.stopCapture()
                self.videoInput?.markAsFinished()
                self.audioInput?.markAsFinished()
                
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
            Task { @MainActor in
                do {
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("Screenshot_\(Date().timeIntervalSince1970).png")
                    switch mode {
                    case .fullScreen:
                        let screenRect = CGRect(x: 0, y: 0, width: CGDisplayPixelsWide(CGMainDisplayID()), height: CGDisplayPixelsHigh(CGMainDisplayID()))
                        let image = try await SCScreenshotManager.captureImage(in: screenRect)
                        let bitmap = NSBitmapImageRep(cgImage: image)
                        if let data = bitmap.representation(using: .png, properties: [:]) {
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
                            self.delegate?.screenCaptureManager(self, didTakeScreenshot: url)
                        } else {
                            self.delegate?.screenCaptureManager(self, didFail: NSError(domain: "ScreenCapture", code: Int(process.terminationStatus), userInfo: nil))
                        }
                    case .window:
                        let process = Process()
                        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
                        process.arguments = ["-w", "-x", "-o", url.path]
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
            Task { @MainActor in
                do {
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("Screenshot_\(Date().timeIntervalSince1970).png")
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
                    switch mode {
                    case .area:
                        process.arguments = ["-s", "-x", url.path]
                    case .window:
                        process.arguments = ["-w", "-x", "-o", url.path]
                    case .fullScreen:
                        process.arguments = ["-x", url.path]
                    }
                    try process.run()
                    process.waitUntilExit()
                    if process.terminationStatus == 0 {
                        if mode == .window {
                            self.handleWindowBackground(at: url)
                        } else {
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
        guard windowBackground != .desktop,
              let image = NSImage(contentsOf: url) else {
            self.delegate?.screenCaptureManager(self, didTakeScreenshot: url)
            return
        }

        let size = image.size
        let newImage = NSImage(size: size)
        newImage.lockFocus()

        switch windowBackground {
        case .white:
            NSColor.white.setFill()
            NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        case .gradient:
            let gradient = NSGradient(colors: [NSColor(calibratedWhite: 0.95, alpha: 1.0), NSColor(calibratedWhite: 0.75, alpha: 1.0)])
            gradient?.draw(in: NSRect(origin: .zero, size: size), angle: 90)
        case .desktop:
            break
        }

        image.draw(at: .zero, from: NSRect(origin: .zero, size: size), operation: .sourceOver, fraction: 1.0)
        newImage.unlockFocus()

        if let tiff = newImage.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let data = rep.representation(using: .png, properties: [:]) {
            try? data.write(to: url)
        }

        self.delegate?.screenCaptureManager(self, didTakeScreenshot: url)
    }

    // MARK: - SCStreamOutput
    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard outputType == .screen else { return }
        // Use unsafe sendable to avoid data race warnings for CMSampleBuffer
        let buffer = sampleBuffer
        Task { @MainActor in
            guard let input = self.videoInput, input.isReadyForMoreMediaData else { return }
            input.append(buffer)
        }
    }

    // MARK: - AudioCaptureManagerDelegate
    nonisolated func audioCaptureManager(_ manager: AudioCaptureManager, didOutput sampleBuffer: CMSampleBuffer) {
        // Use unsafe sendable to avoid data race warnings for CMSampleBuffer
        let buffer = sampleBuffer
        Task { @MainActor in
            guard let input = self.audioInput, input.isReadyForMoreMediaData else { return }
            input.append(buffer)
        }
    }

    nonisolated func audioCaptureManager(_ manager: AudioCaptureManager, didFail error: Error) {
        Task { @MainActor in
            self.delegate?.screenCaptureManager(self, didFail: error)
        }
    }
}
