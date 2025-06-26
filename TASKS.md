# Implementation Tasks for macOS Screen Recording and Capture App

This file breaks down the steps required to implement the application described in **PLAN.md**. The tasks are grouped by phase and roughly ordered.

## 1. Project Setup
- [x] Create a new macOS app in Xcode using SwiftUI.
- [x] Configure entitlements for screen recording and microphone access.
- [x] Establish the folder structure (`Model`, `ViewModel`, `View`).

## 2. Core Logic (Model Layer)
- [x] Implement `ScreenCaptureManager` to:
  - Discover shareable content with `SCShareableContent`.
  - Configure `SCStream` and `SCContentFilter`.
  - Receive samples via `SCStreamOutput` and manage recording.
  - Integrate with `SCScreenshotManager` for screenshots (macOS 14+).
  - Save video using `AVAssetWriter`.
- [x] Implement optional `AudioCaptureManager` for microphone/system audio.
- [x] Create `PersistenceManager` for saving settings and output paths.

## 3. ViewModel Layer
- [x] Build `AppViewModel` exposing app state (`isRecording`, content lists).
- [x] Connect `ScreenCaptureManager` callbacks to update the view model.

## 4. User Interface (View Layer)
- [x] Main window with controls for recording and screenshots.
- [ ] Content selection UI to choose display, app, or window.
- [ ] Live preview of selected content.
- [ ] Settings view for capture parameters.

## 5. System Integration and UX
- [x] Request and handle Screen Recording and microphone permissions.
- [ ] Provide status indicators and error messages.
- [ ] Manage resources to avoid leaks (stop streams, release writers).

## 6. Future Enhancements (Post-MVP)
- [ ] Basic video editing tools (trimming, cropping).
- [ ] Live streaming functionality.
- [ ] Customizable hotkeys for quick actions.
