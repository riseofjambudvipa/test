# Google Play Data Safety Form — CapStudio Submission Guide

*Target Audience:* CapStudio Release Team & Google Play Console Submission  
*Application ID:* `com.capstudio.app`  
*Target SDK:* 36 (Android 15 / 16 compliant)

---

## 1. Overview & Core Privacy Guarantee

CapStudio is an **offline-first, client-side video captioning and editing application**. All AI speech-to-text inference (via Whisper.cpp FFI), subtitle synthesis, video filtering, rendering, and export (via FFmpeg) happen entirely locally on the user's Android hardware.

- **Zero Cloud Uploads:** No user videos, audio tracks, transcriptions, or project files are transmitted to any server.
- **Zero Third-Party Trackers:** No analytics SDKs (Firebase Analytics, Mixpanel, Segment, etc.), advertising networks, or crash-reporting telemetry are bundled in release builds.
- **Zero Account Creation:** The app does not require logins, accounts, email addresses, or phone numbers.

---

## 2. Google Play Console Form Questions & Answers

### 2.1 Data Collection and Security

| Question | Official Answer | Rationale / Explanation |
|---|---|---|
| **Does your app collect or share any of the required user data types?** | **No** | CapStudio processes all media locally on-device. No data is harvested, saved remotely, or distributed. |
| **Is all user data collected by your app encrypted in transit?** | **Yes (Not Applicable)** | If prompted, select Yes. The only outbound network requests are HTTPS downloads of static open-source model weights (e.g., Hugging Face) and content packs. |
| **Do you provide a way for users to request that their data be deleted?** | **Not Applicable / No** | Since zero data is stored off-device, deleting the app or project within the app permanently removes all data locally. |

---

### 2.2 Data Types & Specific Disclosures

When reviewing each category in the Google Play Console:

| Category | Sub-category | Collected? | Shared? | Purpose |
|---|---|---|---|---|
| **Location** | Approximate / Precise | **No** | **No** | N/A |
| **Personal Info** | Name, Email, User IDs, Address, Phone, Political/Religious, Sexual Orientation | **No** | **No** | N/A |
| **Financial Info** | Credit card, Bank info | **No** | **No** | N/A |
| **Health and Fitness** | Health / Fitness info | **No** | **No** | N/A |
| **Messages** | Emails, SMS, in-app messages | **No** | **No** | N/A |
| **Photos and Videos** | Photos, Videos | **No** *(Ephemeral On-Device)* | **No** | Selected videos are opened directly via Android Storage Access Framework (SAF) / MediaStore for local editing and rendering. They are never collected or transmitted. |
| **Audio Files** | Voice or sound recordings | **No** *(Ephemeral On-Device)* | **No** | Audio is extracted locally via FFmpeg to feed the on-device Whisper model. Never sent to any external server. |
| **Files and Docs** | Files and docs | **No** | **No** | N/A |
| **Calendar** | Calendar events | **No** | **No** | N/A |
| **Contacts** | Contacts | **No** | **No** | N/A |
| **App Activity** | Page views, clicks, interactions | **No** | **No** | No tracking SDKs. |
| **App Info and Performance** | Crash logs, Diagnostics, Performance metrics | **No** | **No** | No remote crash reporting. |
| **Device or Other IDs** | Device ID, Advertising ID | **No** | **No** | No advertising or tracking IDs accessed. |

---

### 2.3 Network Permissions Justification

CapStudio requests `android.permission.INTERNET` exclusively for:
1. **Optional Model Downloads:** Users can optionally download quantized Whisper model files (e.g., `ggml-tiny.bin`, `ggml-base.bin`) directly from Hugging Face (`huggingface.co`) over TLS 1.3.
2. **Content Packs:** Users can optionally download free open-source font packs and SFX packages hosted on GitHub Releases.

No user media, credentials, or personal telemetry are sent over these connections.
