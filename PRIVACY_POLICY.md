# CapStudio — Privacy Policy

*Effective Date: September 23, 2026*  
*Application:* CapStudio (Windows, macOS, Linux, Android, iOS, Web)  
*Publisher:* CapStudio Team (`https://capstudio.app`)

---

## 1. Introduction

CapStudio is an offline-first, client-side video captioning and editing application. We believe your creative media, audio, and personal content belong solely to you. This Privacy Policy outlines our principles regarding user data, permissions, and network communication.

---

## 2. Core Privacy Principle: 100% On-Device Processing

CapStudio is engineered from the ground up to operate without cloud dependencies for core video processing:

- **Local AI Speech Recognition:** Audio transcription is executed entirely on your device using optimized on-device models (such as Whisper.cpp via native FFI/Metal/NEON or WebAssembly). Your voice and audio recordings are never sent to external servers or cloud AI providers.
- **Local Video Rendering & Subtitle Burning:** All video encoding, subtitle compositing, and rendering operations are performed locally using FFmpeg on your device hardware.
- **Zero Cloud Storage:** Your original videos, exported clips, captions, and project files are stored strictly on your local disk or device storage.

---

## 3. Data We Do NOT Collect

CapStudio does not harvest, store, share, or sell your data. Specifically:

- **No Personal Information:** We do not collect names, email addresses, phone numbers, postal addresses, or government identifiers.
- **No Account Registration:** Using CapStudio does not require creating an account or logging into any service.
- **No Analytics or Telemetry:** Release builds of CapStudio contain **zero** third-party tracking, telemetry, or analytics SDKs (no Google Analytics, Firebase, Mixpanel, or similar services).
- **No Advertising IDs:** We do not access or collect Advertising Identifiers (IDFA, GAID).
- **No Keystroke or Input Logging:** Your edits, text styling choices, and project contents remain exclusively in your local database.

---

## 4. Network Connections & Downloads

CapStudio requires internet access solely for user-initiated, opt-in downloads:

1. **AI Model Weights:** Users may choose to download quantized Whisper speech recognition models (hosted on Hugging Face over encrypted HTTPS).
2. **Free Open-Source Content Packs:** Users may download optional font packages, sound effects (SFX), and emoji assets (hosted on verified GitHub Releases over encrypted HTTPS).
3. **Automatic Update Checks (Desktop only):** Desktop editions may optionally query the official GitHub API to check if a newer software version is available. No user metadata is transmitted during this check.

No user media, project data, or personal identifiers are ever transmitted during these downloads.

---

## 5. Device Permissions

Depending on your operating system, CapStudio may request the following permissions:

| Platform | Permission | Purpose |
|---|---|---|
| **Android** | `READ_MEDIA_VIDEO` / SAF | To allow you to select and import videos from your device storage. |
| **Android** | `READ_MEDIA_AUDIO` / SAF | To import audio tracks or sound effects chosen by you. |
| **Android** | `INTERNET` | To download optional Whisper model weights or font packs upon request. |
| **iOS / macOS** | `NSPhotoLibraryUsageDescription` | To select videos and media from your Photos library for editing. |
| **iOS / macOS** | `NSPhotoLibraryAddUsageDescription` | To save rendered, captioned videos back to your Photos library. |
| **iOS** | `NSDocumentsFolderUsageDescription` | To read and save video and subtitle project files in the documents folder. |

CapStudio accesses only the files and media you explicitly select.

---

## 6. Local Diagnostic Logs & PII Protection

When running locally, CapStudio writes standard operational logs to your device's application data directory for troubleshooting.

- All local logs pass through an automated privacy scrubber (`LoggerService`) that strips personal paths (such as user home directories, Windows profile usernames, and sensitive environment keys) before writing to disk.
- Diagnostic logs are never uploaded automatically. If you contact support, you may choose to manually share logs at your sole discretion.

---

## 7. Data Retention & Deletion

Because CapStudio stores everything locally on your device:

- You have complete control over your data.
- Deleting a project within the app permanently removes its local database records and cached assets.
- Uninstalling CapStudio removes the application files and associated caches from your system.

---

## 8. Children's Privacy

CapStudio does not knowingly collect any personal information from children under the age of 13 (or under 16 in the European Union). The app does not collect personal data from any user regardless of age.

---

## 9. Changes to this Privacy Policy

We may update this Privacy Policy from time to time to reflect improvements or platform requirements. Any updates will be published in this document and posted to our repository.

---

## 10. Contact Us

If you have questions, feedback, or concerns regarding this Privacy Policy or CapStudio's privacy practices, please contact us at:

- **Email:** `support@capstudio.app`
- **GitHub Issues:** `https://github.com/capstudio/capstudio/issues`
