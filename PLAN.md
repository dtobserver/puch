# macOS Screen Recording and Capture App: Architectural Plan

## 1. Introduction

This document outlines the architectural plan for a macOS application capable of screen recording and screen capturing. The application will leverage Apple's native frameworks, primarily ScreenCaptureKit and AVFoundation, to ensure high performance and tight integration with the macOS ecosystem. The core programming language will be Swift, with SwiftUI for the user interface.

## 2. Core Technologies

### 2.1 ScreenCaptureKit

ScreenCaptureKit is the primary framework for capturing screen content and audio on macOS. It provides granular control over what content is captured (entire displays, specific applications, or individual windows). Key components include:

*   **`SCShareableContent`**: Used to discover available displays, applications, and windows that can be captured.
*   **`SCContentFilter`**: Allows specifying which content to include or exclude from the capture stream. This is crucial for selective recording or capturing.
*   **`SCStream`**: Represents the capture session itself. It delivers video frames as `CMSampleBuffer` objects and audio samples, enabling real-time processing or saving to disk.
*   **`SCStreamConfiguration`**: Configures the properties of the capture stream, such as frame rate, resolution, and audio settings.
*   **`SCStreamOutput`**: A protocol that your app implements to receive the `CMSampleBuffer` objects from the stream.
*   **`SCScreenshotManager`**: (Introduced in macOS 14/WWDC23) Provides programmatic access for taking static screenshots.

### 2.2 AVFoundation

AVFoundation is a comprehensive framework for working with time-based audiovisual media. It will be used for processing and saving the captured `CMSampleBuffer` data. Key components include:

*   **`AVAssetWriter`**: Used to write media data to a new file of a specified type. This is essential for saving recorded video and audio to formats like `.mov` or `.mp4`.
*   **`AVAssetWriterInput`**: Represents a track of media data (e.g., video or audio) within an `AVAssetWriter`. `CMSampleBuffer` objects are appended to these inputs.
*   **`AVAssetWriterInputPixelBufferAdaptor`**: Facilitates appending video frames from `CVPixelBuffer` (which can be extracted from `CMSampleBuffer`) to an `AVAssetWriterInput`.

## 3. Application Architecture

The application will follow a modular architecture, likely based on the MVVM (Model-View-ViewModel) pattern, to ensure separation of concerns, testability, and maintainability. The main layers will be:

*   **Model Layer**: Manages data and business logic. This includes the core screen capture and recording logic, data persistence, and any other non-UI related operations.
*   **ViewModel Layer**: Acts as an intermediary between the View and the Model. It transforms Model data into a format suitable for the View and handles user interactions, updating the Model as necessary.
*   **View Layer**: The user interface, built with SwiftUI, responsible for displaying information and receiving user input.

### 3.1 Component Breakdown

#### 3.1.1 User Interface (View Layer)

*   **Main Window**: Provides controls for starting/stopping recording, taking screenshots, selecting capture areas (display, application, window), and accessing settings.
*   **Content Selection View**: A dedicated view (or part of the main window) that displays available `SCShareableContent` (displays, applications, windows) for the user to choose from. This might involve a custom UI or leveraging the system's `SCContentSharingPicker`.
*   **Preview View**: Displays a live preview of the selected capture area during recording setup or active recording.
*   **Settings View**: Allows users to configure recording parameters (e.g., resolution, frame rate, audio input, output format, save location).

#### 3.1.2 Core Logic (Model Layer)

*   **`ScreenCaptureManager`**: A central class responsible for orchestrating screen recording and capture operations. It will encapsulate the ScreenCaptureKit and AVFoundation logic.
    *   **Responsibilities**: Discovering shareable content, configuring `SCStream`, handling `SCStreamOutput` delegate methods to receive `CMSampleBuffer`s, managing `AVAssetWriter` for saving recordings, and triggering `SCScreenshotManager` for screenshots.
*   **`AudioCaptureManager`**: (Optional, but recommended for full recording) Manages audio input from the microphone or system audio (if permitted and feasible via ScreenCaptureKit or other audio frameworks like CoreAudio).
*   **`PersistenceManager`**: Handles saving user preferences (settings) and managing the output directory for recordings and screenshots.

#### 3.1.3 Data Flow and Communication (ViewModel Layer & Bindings)

*   **`AppViewModel`**: The primary ViewModel that exposes observable properties for the UI (e.g., `isRecording`, `captureMode`, `availableContent`). It will contain methods to trigger actions in the `ScreenCaptureManager` (e.g., `startRecording()`, `takeScreenshot()`).
*   **Bindings**: SwiftUI's data binding mechanisms (`@State`, `@Binding`, `@ObservedObject`, `@EnvironmentObject`) will facilitate communication between the View and ViewModel.
*   **Delegation/Callbacks**: The `ScreenCaptureManager` will use delegates or completion handlers to notify the `AppViewModel` of events such as recording started/stopped, errors, or screenshot completion.

## 4. System Design Considerations

### 4.1 Permissions

*   **Screen Recording Permission**: macOS requires explicit user permission for screen recording. The application must gracefully handle cases where this permission is not granted, guiding the user to enable it in System Settings.
*   **Microphone Permission**: If audio recording is included, microphone access permission will also be required.

### 4.2 Performance Optimization

*   **Efficient `CMSampleBuffer` Handling**: Processing `CMSampleBuffer`s efficiently is critical. This involves minimizing data copying and performing operations on background threads to avoid blocking the main UI thread.
*   **Hardware Acceleration**: ScreenCaptureKit and AVFoundation are designed to leverage hardware acceleration where possible, which should be utilized for optimal performance.
*   **Resource Management**: Proper management of `SCStream` and `AVAssetWriter` resources (starting, stopping, releasing) is essential to prevent memory leaks or performance degradation.

### 4.3 Error Handling

*   **Permission Denied**: Provide clear user feedback and instructions if permissions are denied.
*   **Capture Errors**: Handle potential errors during screen capture (e.g., content no longer available, stream interruption).
*   **File Writing Errors**: Gracefully handle errors during file writing (e.g., disk full, invalid path).

### 4.4 User Experience

*   **Intuitive UI**: A clean and intuitive user interface is paramount for ease of use.
*   **Live Preview**: A live preview of the captured content enhances the user experience and helps in accurate selection.
*   **Status Indicators**: Clear visual indicators for recording status (recording, paused, stopped) and any errors.
*   **System Integration**: Consider integrating with macOS features like the menu bar icon, notifications, and potentially keyboard shortcuts.

## 5. Future Enhancements (Beyond Initial Scope)

*   **Editing Features**: Basic trimming, cropping, or annotation tools for recorded videos/screenshots.
*   **Streaming Capabilities**: Live streaming of screen content to various platforms.
*   **Advanced Audio Options**: More sophisticated audio routing and mixing.
*   **Customizable Hotkeys**: User-definable keyboard shortcuts for common actions.

## 6. Conclusion

This architectural plan provides a solid foundation for developing a robust and high-performance macOS screen recording and capture application using Swift and Apple's native frameworks. By adhering to a modular design, prioritizing performance, and focusing on user experience, the application can deliver a seamless and efficient solution for capturing screen content.

