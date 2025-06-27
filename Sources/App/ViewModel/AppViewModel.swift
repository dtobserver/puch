import Foundation
import Combine

@MainActor
class AppViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var lastRecordingURL: URL?
    @Published var lastScreenshotURL: URL?
    @Published var permissionsGranted = false
    @Published var recordAudio = false
    @Published var windowScreenshotBackground: PersistenceManager.Settings.WindowScreenshotBackground = .desktop {
        didSet {
            persistenceSettings.windowScreenshotBackground = windowScreenshotBackground
            PersistenceManager.shared.saveSettings(persistenceSettings)
            screenManager.windowBackground = windowScreenshotBackground
        }
    }
    @Published var errorMessage: String?

    let screenManager: ScreenCaptureManager
    private var permissionMonitorTimer: Timer?
    private var persistenceSettings: PersistenceManager.Settings

    init() {
        let loaded = PersistenceManager.shared.loadSettings() ?? .default
        persistenceSettings = loaded
        screenManager = ScreenCaptureManager()
        screenManager.delegate = self
        windowScreenshotBackground = loaded.windowScreenshotBackground
        screenManager.windowBackground = windowScreenshotBackground
        setupNotificationObservers()
        checkPermissionsStatus()
        startPermissionMonitoring()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .takeScreenshot,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.takeScreenshot()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .toggleRecording,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                if self?.isRecording == true {
                    self?.stopRecording()
                } else {
                    self?.startRecording()
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        // Timer cleanup will happen automatically when the object is deallocated
    }

    func startRecording() {
        screenManager.startRecording(withAudio: recordAudio)
    }

    func stopRecording() {
        screenManager.stopRecording()
    }

    func takeScreenshot(mode: ScreenshotMode = .fullScreen) {
        screenManager.takeScreenshot(mode: mode)
    }

    func requestPermissions() {
        PermissionManager.requestPermissions { [weak self] granted in
            Task { @MainActor in
                self?.permissionsGranted = granted
            }
        }
    }
    
    private func checkPermissionsStatus() {
        let status = PermissionManager.checkPermissionsStatus()
        // For screen recording, we primarily need screen permission
        // Audio permission is only required when recording with audio
        permissionsGranted = status.screen
    }
    
    private func startPermissionMonitoring() {
        // Check permissions status every 2 seconds
        permissionMonitorTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPermissionsStatus()
            }
        }
    }
}

extension AppViewModel: ScreenCaptureManagerDelegate {
    func screenCaptureManagerDidStartRecording(_ manager: ScreenCaptureManager) {
        isRecording = true
    }

    func screenCaptureManager(_ manager: ScreenCaptureManager, didFinishRecordingTo url: URL?) {
        isRecording = false
        lastRecordingURL = url
    }

    func screenCaptureManager(_ manager: ScreenCaptureManager, didTakeScreenshot url: URL) {
        lastScreenshotURL = url
    }

    func screenCaptureManager(_ manager: ScreenCaptureManager, didFail error: Error) {
        isRecording = false
        errorMessage = error.localizedDescription
        print("ScreenCapture error: \(error)")
    }
}
