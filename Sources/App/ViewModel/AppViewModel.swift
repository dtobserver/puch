import Foundation
import Combine

@MainActor
class AppViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var lastRecordingURL: URL?
    @Published var lastScreenshotURL: URL?
    @Published var permissionsGranted = false
    @Published var recordAudio = false {
        didSet {
            // When user enables audio recording, check if we need to request microphone permission
            if recordAudio && !PermissionManager.hasMicrophonePermission() {
                requestMicrophonePermission()
            }
        }
    }
    @Published var windowScreenshotBackground: PersistenceManager.Settings.WindowScreenshotBackground = .wallpaper {
        didSet {
            persistenceSettings.windowScreenshotBackground = windowScreenshotBackground
            PersistenceManager.shared.saveSettings(persistenceSettings)
            screenManager.windowBackground = windowScreenshotBackground
        }
    }
    @Published var saveLocation: URL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory {
        didSet {
            persistenceSettings.outputDirectory = saveLocation
            PersistenceManager.shared.saveSettings(persistenceSettings)
            screenManager.outputDirectory = saveLocation
        }
    }
    @Published var errorMessage: String?

    let screenManager: ScreenCaptureManager
    let floatingBadgeManager: FloatingBadgeManager
    private var permissionMonitorTimer: Timer?
    private var persistenceSettings: PersistenceManager.Settings

    init() {
        let loaded = PersistenceManager.shared.loadSettings() ?? .default
        persistenceSettings = loaded
        screenManager = ScreenCaptureManager()
        floatingBadgeManager = FloatingBadgeManager()
        screenManager.delegate = self
        windowScreenshotBackground = loaded.windowScreenshotBackground
        saveLocation = loaded.outputDirectory
        screenManager.windowBackground = windowScreenshotBackground
        screenManager.outputDirectory = saveLocation
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
        // Check if audio recording is enabled and we don't have microphone permission
        if recordAudio && !PermissionManager.hasMicrophonePermission() {
            requestMicrophonePermission { [weak self] granted in
                Task { @MainActor in
                    if granted {
                        self?.screenManager.startRecording(withAudio: self?.recordAudio ?? false)
                    } else {
                        self?.errorMessage = "Microphone permission is required for audio recording. Please enable it in System Settings."
                    }
                }
            }
        } else {
            screenManager.startRecording(withAudio: recordAudio)
        }
    }

    func stopRecording() {
        screenManager.stopRecording()
    }

    func takeScreenshot(mode: ScreenshotMode = .fullScreen) {
        screenManager.takeScreenshot(mode: mode)
    }

    func requestPermissions() {
        PermissionManager.requestScreenRecordingPermission { [weak self] granted in
            Task { @MainActor in
                self?.permissionsGranted = granted
                if !granted {
                    self?.errorMessage = "Screen recording permission is required. Please enable it in System Settings."
                }
            }
        }
    }
    
    private func requestMicrophonePermission(completion: (@Sendable (Bool) -> Void)? = nil) {
        PermissionManager.requestMicrophonePermission { [weak self] granted in
            Task { @MainActor in
                if !granted {
                    self?.recordAudio = false
                    self?.errorMessage = "Microphone permission denied. Audio recording has been disabled."
                }
                completion?(granted)
            }
        }
    }
    
    private func checkPermissionsStatus() {
        let status = PermissionManager.checkPermissionsStatus()
        // For screen recording, we primarily need screen permission
        // Audio permission is only checked when recording with audio
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
        // Show floating badge for the new screenshot
        floatingBadgeManager.showBadge(for: url)
    }

    func screenCaptureManager(_ manager: ScreenCaptureManager, didFail error: Error) {
        isRecording = false
        errorMessage = error.localizedDescription
        print("ScreenCapture error: \(error)")
    }
}
