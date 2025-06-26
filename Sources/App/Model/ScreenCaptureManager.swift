import Foundation
@preconcurrency import AVFoundation
@preconcurrency import ScreenCaptureKit
import CoreGraphics

@MainActor
protocol ScreenCaptureManagerDelegate: AnyObject {
    func screenCaptureManagerDidStartRecording(_ manager: ScreenCaptureManager)
    func screenCaptureManager(_ manager: ScreenCaptureManager, didFinishRecordingTo url: URL?)
    func screenCaptureManager(_ manager: ScreenCaptureManager, didTakeScreenshot url: URL)
    func screenCaptureManager(_ manager: ScreenCaptureManager, didFail error: Error)
}

@MainActor
class ScreenCaptureManager: NSObject, SCStreamOutput, AudioCaptureManagerDelegate {
    weak var delegate: ScreenCaptureManagerDelegate?

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

    func takeScreenshot() {
        if #available(macOS 15.2, *) {
            Task { @MainActor in
                do {
                    // Use the full screen rect for capture
                    let screenRect = CGRect(x: 0, y: 0, width: CGDisplayPixelsWide(CGMainDisplayID()), height: CGDisplayPixelsHigh(CGMainDisplayID()))
                    let image = try await SCScreenshotManager.captureImage(in: screenRect)
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("Screenshot_\(Date().timeIntervalSince1970).png")
                    let bitmap = NSBitmapImageRep(cgImage: image)
                    if let data = bitmap.representation(using: .png, properties: [:]) {
                        try data.write(to: url)
                        self.delegate?.screenCaptureManager(self, didTakeScreenshot: url)
                    }
                } catch {
                    self.delegate?.screenCaptureManager(self, didFail: error)
                }
            }
        } else {
            // Fallback for older macOS versions - use alternative screenshot method
            Task { @MainActor in
                do {
                    let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                    guard let display = content.displays.first else { return }
                    
                    let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
                    let configuration = SCStreamConfiguration()
                    configuration.width = display.width
                    configuration.height = display.height
                    configuration.showsCursor = false
                    configuration.capturesAudio = false
                    
                    let _ = SCStream(filter: filter, configuration: configuration, delegate: nil)
                    // For older versions, we'd need to implement a different approach
                    // This is a simplified placeholder - in practice you'd capture a single frame
                    self.delegate?.screenCaptureManager(self, didFail: NSError(domain: "ScreenCapture", code: -1, userInfo: [NSLocalizedDescriptionKey: "Screenshot not supported on this macOS version"]))
                } catch {
                    self.delegate?.screenCaptureManager(self, didFail: error)
                }
            }
        }
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
