import Foundation
import AVFoundation

protocol AudioCaptureManagerDelegate: AnyObject {
    func audioCaptureManager(_ manager: AudioCaptureManager, didOutput sampleBuffer: CMSampleBuffer)
    func audioCaptureManager(_ manager: AudioCaptureManager, didFail error: Error)
}

class AudioCaptureManager: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    weak var delegate: AudioCaptureManagerDelegate?

    private let session = AVCaptureSession()
    private let output = AVCaptureAudioDataOutput()
    private var input: AVCaptureDeviceInput?
    private let queue = DispatchQueue(label: "AudioCaptureQueue")

    func startCapturing() {
        session.beginConfiguration()
        do {
            if let device = AVCaptureDevice.default(for: .audio) {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                    self.input = input
                }
            }
            if session.canAddOutput(output) {
                output.setSampleBufferDelegate(self, queue: queue)
                session.addOutput(output)
            }
            session.commitConfiguration()
            session.startRunning()
        } catch {
            delegate?.audioCaptureManager(self, didFail: error)
        }
    }

    func stopCapturing() {
        session.stopRunning()
        if let input {
            session.removeInput(input)
        }
        session.removeOutput(output)
    }

    // MARK: - AVCaptureAudioDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.audioCaptureManager(self, didOutput: sampleBuffer)
    }
}
