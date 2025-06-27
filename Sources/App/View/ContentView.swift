import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var recordingTime: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @State private var showingSettings = false
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // Background with blur effect
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 24) {
                // Header Section
                headerSection
                
                // Recording Status Section
                recordingStatusSection
                
                // Audio Toggle Section
                audioToggleSection
                
                // Main Control Buttons
                mainControlButtons
                
                // File Information Section
                fileInfoSection
                
                Spacer()
            }
            .padding(24)
        }
        .frame(width: 380, height: 480)
        .onAppear {
            viewModel.requestPermissions()
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
        .alert("Permissions Required", isPresented: .constant(!viewModel.permissionsGranted)) {
            Button("Open Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable screen recording access in System Settings to use this app. Microphone access will be requested only when you enable audio recording.")
        }
        .onChange(of: viewModel.isRecording) { isRecording in
            if isRecording {
                startRecordingTimer()
            } else {
                stopRecordingTimer()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Puch")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("Screen Capture")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: { showingSettings.toggle() }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    // Add hover effect if needed
                }
            }
        }
    }
    
    // MARK: - Recording Status Section
    private var recordingStatusSection: some View {
        HStack(spacing: 12) {
            // Recording indicator
            Circle()
                .fill(viewModel.isRecording ? .red : .gray.opacity(0.3))
                .frame(width: 12, height: 12)
                .scaleEffect(pulseAnimation && viewModel.isRecording ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)
                .onAppear {
                    pulseAnimation = true
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.isRecording ? "Recording in Progress" : "Ready to Capture")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                if viewModel.isRecording {
                    Text(formatTime(recordingTime))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Click Start to begin recording")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.isRecording ? Color.red.opacity(0.1) : Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(viewModel.isRecording ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Audio Toggle Section
    private var audioToggleSection: some View {
        HStack {
            Image(systemName: viewModel.recordAudio ? "mic.fill" : "mic.slash.fill")
                .font(.system(size: 16))
                .foregroundStyle(viewModel.recordAudio ? .blue : .secondary)
            
            Text("Record Audio")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
            
            Spacer()
            
            Toggle("", isOn: $viewModel.recordAudio)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Main Control Buttons
    private var mainControlButtons: some View {
        HStack(spacing: 16) {
            // Start/Stop Recording Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                    }
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isRecording ? "stop.fill" : "record.circle")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text(viewModel.isRecording ? "Stop" : "Record")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(height: 48)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: viewModel.isRecording ? [.red, .red.opacity(0.8)] : [.blue, .blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .shadow(color: (viewModel.isRecording ? Color.red : Color.blue).opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!viewModel.permissionsGranted)
            .opacity(viewModel.permissionsGranted ? 1.0 : 0.5)
            .scaleEffect(viewModel.permissionsGranted ? 1.0 : 0.95)
            
            // Screenshot Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.takeScreenshot()
                }
            }) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - File Information Section
    private var fileInfoSection: some View {
        VStack(spacing: 12) {
            if let screenshot = viewModel.lastScreenshotURL {
                fileInfoRow(
                    icon: "photo.fill",
                    title: "Last Screenshot",
                    filename: screenshot.lastPathComponent,
                    color: .green,
                    url: screenshot
                )
            }
            
            if let recording = viewModel.lastRecordingURL {
                fileInfoRow(
                    icon: "video.fill",
                    title: "Last Recording",
                    filename: recording.lastPathComponent,
                    color: .blue,
                    url: recording
                )
            }
        }
    }
    
    private func fileInfoRow(icon: String, title: String, filename: String, color: Color, url: URL) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.1), in: Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text(filename)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: {
                NSWorkspace.shared.open(url)
            }) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Helper Functions
    private func startRecordingTimer() {
        recordingTime = 0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                recordingTime += 1
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingTime = 0
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(AppViewModel())
    }
}
