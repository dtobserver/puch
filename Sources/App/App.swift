import SwiftUI

@main
struct Puch: App {
    @StateObject private var viewModel = AppViewModel()
    @StateObject private var menuBarManager = MenuBarManager()
    
    var body: some Scene {
        MenuBarExtra("Puch", systemImage: viewModel.isRecording ? "record.circle.fill" : "camera.macro") {
            MenuBarView()
                .environmentObject(viewModel)
                .environmentObject(menuBarManager)
        }
        .menuBarExtraStyle(.menu)
        
        // Settings Window
        WindowGroup("Settings", id: "settings") {
            SettingsView()
                .environmentObject(viewModel)
                .frame(width: 480, height: 360)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        
        // History Window  
        WindowGroup("Capture History", id: "history") {
            HistoryView()
                .environmentObject(viewModel)
                .frame(width: 600, height: 400)
        }
        .windowResizability(.contentMinSize)
        .defaultPosition(.center)
    }
}
