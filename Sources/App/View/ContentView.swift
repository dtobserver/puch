import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        VStack {
            Text(viewModel.isRecording ? "Recording..." : "Ready")
                .padding()
            HStack {
                Button(action: viewModel.startRecording) {
                    Text("Start")
                }.disabled(viewModel.isRecording)
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
    }
}

#Preview {
    ContentView().environmentObject(AppViewModel())
}
