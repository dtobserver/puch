import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var screenshotHotkey = "⌘⇧3"
    @State private var recordingHotkey = "⌘⇧5"
    @State private var saveLocation = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
    @State private var showingFileImporter = false
    
    var body: some View {
        TabView {
            // General Settings Tab
            GeneralSettingsView(viewModel: viewModel, saveLocation: $saveLocation, showingFileImporter: $showingFileImporter)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            // Hotkeys Settings Tab
            HotkeysSettingsView(screenshotHotkey: $screenshotHotkey, recordingHotkey: $recordingHotkey)
                .tabItem {
                    Label("Hotkeys", systemImage: "keyboard")
                }
            
            // About Tab
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 480, height: 360)
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    saveLocation = url
                }
            case .failure(let error):
                print("File selection error: \(error)")
            }
        }
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var saveLocation: URL
    @Binding var showingFileImporter: Bool
    
    var body: some View {
        Form {
            Section("Recording") {
                Toggle("Record Audio by Default", isOn: $viewModel.recordAudio)
                    .help("Enable audio recording for screen recordings")
            }

            Section("Window Screenshot") {
                Picker("Background", selection: $viewModel.windowScreenshotBackground) {
                    Text("Desktop").tag(PersistenceManager.Settings.WindowScreenshotBackground.desktop)
                    Text("White").tag(PersistenceManager.Settings.WindowScreenshotBackground.white)
                    Text("Gradient").tag(PersistenceManager.Settings.WindowScreenshotBackground.gradient)
                }
                .pickerStyle(.segmented)
            }
            
            Section("File Management") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Save Location")
                            .font(.headline)
                        Text(saveLocation.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Choose...") {
                        showingFileImporter = true
                    }
                }
                
                Toggle("Open file location after capture", isOn: .constant(true))
                    .help("Automatically reveal captured files in Finder")
                
                Toggle("Copy to clipboard after screenshot", isOn: .constant(false))
                    .help("Automatically copy screenshots to clipboard")
            }
            
            Section("Notifications") {
                Toggle("Show capture notifications", isOn: .constant(true))
                    .help("Display system notifications when captures are complete")
                
                Toggle("Play sound on capture", isOn: .constant(false))
                    .help("Play a sound effect when taking screenshots")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct HotkeysSettingsView: View {
    @Binding var screenshotHotkey: String
    @Binding var recordingHotkey: String
    
    var body: some View {
        Form {
            Section("Global Hotkeys") {
                HStack {
                    Text("Take Screenshot")
                    Spacer()
                    Text(screenshotHotkey)
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                }
                
                HStack {
                    Text("Toggle Recording")
                    Spacer()
                    Text(recordingHotkey)
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                }
            }
            
            Section {
                Text("Hotkey customization will be available in a future update.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.macro")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            VStack(spacing: 8) {
                Text("Puch")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Screen Capture")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 12) {
                Text("A simple and powerful screen capture tool for macOS")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 16) {
                    Link("GitHub", destination: URL(string: "https://github.com/")!)
                    Link("Support", destination: URL(string: "mailto:support@example.com")!)
                }
                .font(.caption)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
} 