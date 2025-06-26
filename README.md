# Puch - macOS Screen Recording & Capture App

A powerful, lightweight **menu bar** screen capture application for macOS with global hotkeys and intuitive interface.

## ✨ Key Features

### 🎯 **Menu Bar First Design**
- **Always Accessible**: Lives in your menu bar, never clutters your desktop
- **Dynamic Status**: Visual indicator shows recording state
- **Quick Access**: One-click access to all capture functions
- **Non-intrusive**: Stays out of your way until needed

### ⌨️ **Global Hotkeys** 
- **Screenshot**: `⌘⇧3` - Instant full screen capture
- **Recording**: `⌘⇧5` - Toggle screen recording on/off
- **System-wide**: Works from any app, no need to switch windows
- **Native Feel**: follows macOS screenshot conventions

### 📹 **Advanced Recording**
- **High-quality**: Full resolution screen recording
- **Audio support**: Optional microphone recording  
- **Efficient encoding**: Uses native H.264/AAC codecs
- **Smart file management**: Automatic timestamped naming

### 🎨 **Modern Interface**
- **Settings Window**: Comprehensive preferences when needed
- **History Window**: Visual browser for all your captures
- **Native Design**: Follows macOS Human Interface Guidelines
- **Separate Concerns**: Main actions via menu bar, detailed management via dedicated windows

## Prerequisites

- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 14.0 or later
- **Swift**: 5.7 or later
- **Hardware**: Apple Silicon (M1/M2) or Intel Mac with macOS 13+

> **Note**: ScreenCaptureKit requires macOS 12.3+, but some features like `SCScreenshotManager` require macOS 14+.

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd puch
```

### 2. Open in Xcode

```bash
open Package.swift
```

Alternatively, you can:
- Open Xcode
- Select "Open a project or file"
- Navigate to the `puch` directory and select `Package.swift`

### 3. Configure Code Signing

1. In Xcode, select the project in the navigator
2. Under "Signing & Capabilities":
   - Select your development team
   - Ensure "Automatically manage signing" is checked
   - Verify the bundle identifier is unique (e.g., `com.yourname.puch`)

### 4. Verify Entitlements

The project includes `Puch.entitlements` with necessary permissions:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.device.camera</key>
    <true/>
    <key>com.apple.security.device.microphone</key>
    <true/>
    <key>com.apple.security.device.screen-capture</key>
    <true/>
</dict>
</plist>
```

## Running the Application

### 1. Build and Run

In Xcode:
- Press `Cmd + R` or click the "Run" button
- The app will build and launch

### 2. Grant Permissions

When first running the app, macOS will request permissions:

1. **Screen Recording Permission**:
   - Go to System Settings > Privacy & Security > Screen Recording
   - Enable permission for your app

2. **Microphone Permission** (if using audio):
   - Go to System Settings > Privacy & Security > Microphone
   - Enable permission for your app

3. **Camera Permission** (if implemented):
   - Go to System Settings > Privacy & Security > Camera
   - Enable permission for your app

### 3. Restart the App

After granting permissions, restart the application for changes to take effect.

## Development Setup

### Project Structure

```
puch/
├── Package.swift                    # Swift Package Manager configuration
├── Puch.entitlements   # App permissions and entitlements
├── Sources/
│   └── App/
│       ├── App.swift               # Main app entry point
│       ├── Model/                  # Business logic layer
│       │   ├── AudioCaptureManager.swift
│       │   ├── PermissionManager.swift
│       │   ├── PersistenceManager.swift
│       │   └── ScreenCaptureManager.swift
│       ├── View/                   # SwiftUI views
│       │   └── ContentView.swift
│       └── ViewModel/              # MVVM view models
│           └── AppViewModel.swift
├── PLAN.md                         # Architectural documentation
└── TASKS.md                        # Development tasks
```

### Key Dependencies

The project uses native macOS frameworks:
- **ScreenCaptureKit**: For screen capture and recording
- **AVFoundation**: For media processing and file writing
- **SwiftUI**: For the user interface
- **Combine**: For reactive programming patterns

### Building from Command Line

```bash
# Build the project
swift build

# Run tests (when available)
swift test

# Create a release build
swift build -c release
```

## Troubleshooting

### Common Issues

1. **"Screen Recording permission denied"**
   - Solution: Grant permission in System Settings > Privacy & Security > Screen Recording

2. **"App crashes on launch"**
   - Ensure you're running macOS 13.0 or later
   - Check that all entitlements are properly configured
   - Verify code signing is set up correctly

3. **"No shareable content found"**
   - Make sure screen recording permission is granted
   - Try restarting the app after granting permissions

4. **Build errors in Xcode**
   - Clean build folder: `Cmd + Shift + K`
   - Ensure Xcode version 14.0 or later
   - Check Swift version compatibility

### Performance Tips

- The app uses hardware acceleration when available
- For best performance, use on Apple Silicon Macs
- Ensure sufficient disk space for recordings
- Close unnecessary apps during intensive recording sessions

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Test thoroughly on different macOS versions
5. Submit a pull request

## License

[Add your license information here]

## Support

For issues and questions:
- Check the [troubleshooting section](#troubleshooting)
- Review the [PLAN.md](PLAN.md) for architectural details
- Open an issue on the repository

## Acknowledgments

Built using Apple's native frameworks:
- ScreenCaptureKit for screen capture functionality
- AVFoundation for media processing
- SwiftUI for the user interface 