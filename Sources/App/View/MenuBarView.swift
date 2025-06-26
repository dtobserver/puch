import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @EnvironmentObject var menuBarManager: MenuBarManager
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "camera.macro")
                    .foregroundStyle(.blue)
                Text("Puch")
                    .font(.headline)
                Spacer()
                if viewModel.isRecording {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.red)
                            .frame(width: 6, height: 6)
                        Text("Recording")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            // Main Actions
            Group {
                MenuButton(
                    icon: "camera.fill",
                    title: "Full Screenshot",
                    shortcut: "⌘⇧3",
                    color: .green
                ) {
                    viewModel.takeScreenshot()
                }
                .disabled(!viewModel.permissionsGranted)

                MenuButton(
                    icon: "macwindow.on.rectangle",
                    title: "Window Screenshot",
                    color: .green
                ) {
                    viewModel.takeScreenshot(mode: .window)
                }
                .disabled(!viewModel.permissionsGranted)

                MenuButton(
                    icon: "crop",
                    title: "Area Screenshot",
                    color: .green
                ) {
                    viewModel.takeScreenshot(mode: .area)
                }
                .disabled(!viewModel.permissionsGranted)
                
                MenuButton(
                    icon: viewModel.isRecording ? "stop.fill" : "record.circle",
                    title: viewModel.isRecording ? "Stop Recording" : "Start Recording",
                    shortcut: "⌘⇧5",
                    color: viewModel.isRecording ? .red : .blue
                ) {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                    }
                }
                .disabled(!viewModel.permissionsGranted)
                
                Toggle(isOn: $viewModel.recordAudio) {
                    HStack {
                        Image(systemName: viewModel.recordAudio ? "mic.fill" : "mic.slash.fill")
                            .foregroundStyle(viewModel.recordAudio ? .blue : .secondary)
                            .frame(width: 20)
                        Text("Record Audio")
                        Spacer()
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            
            Divider()
            
            // Secondary Actions
            Group {
                MenuButton(
                    icon: "clock.arrow.circlepath",
                    title: "Show History",
                    shortcut: "⌘H"
                ) {
                    openWindow(id: "history")
                }
                
                MenuButton(
                    icon: "gearshape",
                    title: "Settings",
                    shortcut: "⌘,"
                ) {
                    openWindow(id: "settings")
                }
            }
            
            Divider()
            
            // Recent Files (if any)
            if let screenshot = viewModel.lastScreenshotURL {
                RecentFileRow(
                    icon: "photo.fill",
                    filename: screenshot.lastPathComponent,
                    color: .green,
                    url: screenshot
                )
            }
            
            if let recording = viewModel.lastRecordingURL {
                RecentFileRow(
                    icon: "video.fill",
                    filename: recording.lastPathComponent,
                    color: .blue,
                    url: recording
                )
            }
            
            if !viewModel.permissionsGranted {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Permissions Required")
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                    
                    Button("Open System Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            
            Divider()
            
            // Quit Button
            MenuButton(
                icon: "power",
                title: "Quit Puch",
                shortcut: "⌘Q",
                color: .secondary
            ) {
                NSApplication.shared.terminate(nil)
            }
        }
        .frame(width: 280)
        .onAppear {
            viewModel.requestPermissions()
        }
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    let shortcut: String?
    let color: Color
    let action: () -> Void
    
    init(icon: String, title: String, shortcut: String? = nil, color: Color = .primary, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.shortcut = shortcut
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 20)
                
                Text(title)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            // Add hover effect if needed
        }
    }
}

struct RecentFileRow: View {
    let icon: String
    let filename: String
    let color: Color
    let url: URL
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Recent")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(filename)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: {
                NSWorkspace.shared.open(url)
            }) {
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
} 