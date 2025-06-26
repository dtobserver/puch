import Foundation
import AVFoundation

class AudioCaptureManager {
    private let session = AVCaptureSession()
    private let output = AVCaptureAudioDataOutput()
    private var input: AVCaptureDeviceInput?

    func startCapturing() {
        session.beginConfiguration()
        if let device = AVCaptureDevice.default(for: .audio) {
            input = try? AVCaptureDeviceInput(device: device)
            if let input, session.canAddInput(input) {
                session.addInput(input)
            }
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()
        session.startRunning()
    }

    func stopCapturing() {
        session.stopRunning()
        if let input {
            session.removeInput(input)
        }
        session.removeOutput(output)
    }
}
