import SwiftUI

@main
struct ScreenCaptureApp: App {
    @StateObject private var viewModel = AppViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
