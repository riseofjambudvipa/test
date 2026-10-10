# Apple App Store Review Notes & Technical Reviewer Guide

*Target Audience:* Apple App Review Team & Release Engineers  
*Bundle Identifier:* `com.capstudio.ai`  
*Target Platforms:* iOS 16.0+ (iPhone & iPad), macOS 12.0+  

---

## 1. App Summary & Architecture

CapStudio is a privacy-first video captioning and editing studio designed for creators, educators, and social media producers. It allows users to import videos, transcribe spoken dialogue into synchronized animated subtitles, apply styling presets, and export high-resolution captioned videos.

### Privacy & Offline Architecture
- **100% On-Device AI:** Speech recognition is performed locally using an embedded, optimized C++ port of OpenAI's Whisper model (`whisper.cpp`) leveraging Apple Silicon Metal GPU acceleration (`ggml-metal.metal`).
- **No Cloud Uploads:** No user videos, audio tracks, or transcriptions ever leave the device.
- **No User Accounts:** There is no registration, login, subscription wall, or user tracking.

---

## 2. Reviewer Instructions & Demo Flow

Reviewers can test full functionality immediately without entering any credentials:

1. **Launch App:** The app opens directly to the local Projects Dashboard.
2. **Create Project:** Tap **"New Project"** / **"+"** button.
3. **Select Video:** Choose any short video clip from the iOS Photo Library (a sample video with clear English or multilingual speech is recommended).
4. **Transcription:** Tap **"Transcribe"**. The app transcribes the audio using the built-in local model.
5. **Caption Styling:** Tap any caption style preset (e.g. "Trending", "Ali Abdaal", "MrBeast") to preview dynamic caption animations.
6. **Export:** Tap **"Export Video"** to render and save the final captioned video directly into the device's Photos library.

---

## 3. iOS Permissions Rationale

CapStudio requests the following permissions, declared in `Info.plist` and `PrivacyInfo.xcprivacy`:

| Permission | `Info.plist` Key | Justification for Reviewer |
|---|---|---|
| **Photo Library (Read)** | `NSPhotoLibraryUsageDescription` | Required to allow the user to select and import their own video files into the editor. |
| **Photo Library (Add Only)** | `NSPhotoLibraryAddUsageDescription` | Required to save the rendered, captioned MP4 video directly to the user's Camera Roll via the PhotoKit API. |
| **Documents Folder** | `NSDocumentsFolderUsageDescription` | Required for reading and saving video and subtitle project files in the app's document container. |

---

## 4. Network Connections & Downloads

While core processing is offline:
- The app may connect to `huggingface.co` or `github.com` via secure HTTPS strictly when the user manually opts to download additional Whisper model weights (e.g., multilingual `small` or `medium` models) or free open-source font/SFX packs from the in-app Pack Manager.
- Zero analytics, telemetry, or user data packets are transmitted across the network.

---

## 5. Contact & Support

If the review team requires any technical clarification or specialized builds:
- **Developer Support:** `support@capstudio.ai`
- **Technical Lead:** `developer@capstudio.ai`
