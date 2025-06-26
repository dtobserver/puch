import Foundation
import AVFoundation
import ScreenCaptureKit
import CoreGraphics

protocol ScreenCaptureManagerDelegate: AnyObject {
    func screenCaptureManagerDidStartRecording(_ manager: ScreenCaptureManager)
    func screenCaptureManager(_ manager: ScreenCaptureManager, didFinishRecordingTo url: URL?)
    func screenCaptureManager(_ manager: ScreenCaptureManager, didTakeScreenshot url: URL)
    func screenCaptureManager(_ manager: ScreenCaptureManager, didFail error: Error)
}

class ScreenCaptureManager: NSObject, SCStreamOutput {
    weak var delegate: ScreenCaptureManagerDelegate?

    private var stream: SCStream?
    private var writer: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private let queue = DispatchQueue(label: "ScreenCaptureQueue")

    func startRecording() {
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                guard let display = content.displays.first else { return }
                let filter = SCContentFilter(display: display, excludingWindows: [], exceptingApplications: [])
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

                writer.startWriting()
                writer.startSession(atSourceTime: .zero)
                try stream.startCapture()
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.delegate?.screenCaptureManagerDidStartRecording(self)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.delegate?.screenCaptureManager(self, didFail: error)
                }
            }
        }
    }

    func stopRecording() {
        queue.async { [self] in
            stream?.stopCapture { error in
                if let error {
                    self.delegate?.screenCaptureManager(self, didFail: error)
                }
                self.videoInput?.markAsFinished()
                self.writer?.finishWriting {
                    let url = self.writer?.outputURL
                    self.stream = nil
                    self.writer = nil
                    self.videoInput = nil
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        self.delegate?.screenCaptureManager(self, didFinishRecordingTo: url)
                    }
                }
            }
        }
    }

    func takeScreenshot() {
        if #available(macOS 14, *) {
            Task {
                do {
                    let manager = SCScreenshotManager()
                    let image = try await manager.captureImage()
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("Screenshot_\(Date().timeIntervalSince1970).png")
                    if let bitmap = NSBitmapImageRep(cgImage: image), let data = bitmap.representation(using: .png, properties: [:]) {
                        try data.write(to: url)
                        DispatchQueue.main.async { [weak self] in
                            guard let self else { return }
                            self.delegate?.screenCaptureManager(self, didTakeScreenshot: url)
                        }
                    }
                } catch {
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        self.delegate?.screenCaptureManager(self, didFail: error)
                    }
                }
            }
        }
    }

    // MARK: - SCStreamOutput
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard outputType == .screen, let input = videoInput, input.isReadyForMoreMediaData else { return }
        input.append(sampleBuffer)
    }
}
