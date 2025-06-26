import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        VStack {
            Text(viewModel.isRecording ? "Recording..." : "Ready")
                .padding()
            Toggle("Record Audio", isOn: $viewModel.recordAudio)
                .padding(.horizontal)
            HStack {
                Button(action: viewModel.startRecording) {
                    Text("Start")
                }.disabled(viewModel.isRecording || !viewModel.permissionsGranted)
                Button(action: viewModel.stopRecording) {
                    Text("Stop")
                }.disabled(!viewModel.isRecording)
                Button(action: viewModel.takeScreenshot) {
                    Text("Screenshot")
                }
            }
            if let shot = viewModel.lastScreenshotURL {
                Text("Screenshot: \(shot.lastPathComponent)")
                    .font(.footnote)
            }
            if let record = viewModel.lastRecordingURL {
                Text("Recording: \(record.lastPathComponent)")
                    .font(.footnote)
            }
        }
        .frame(width: 300, height: 220)
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
        .alert("Permissions Denied", isPresented: .constant(!viewModel.permissionsGranted)) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please enable screen recording and microphone access in Settings.")
        }
    }
}

#Preview {
    ContentView().environmentObject(AppViewModel())
}
