# CapStudio Privacy Policy

_Last updated: August 16, 2026_

This privacy policy explains how CapStudio ("the app", "we") handles your
information. It applies to the CapStudio application on Android, iOS, Windows,
macOS, Linux, and the Web.

## Summary

CapStudio is a **local-first** video caption editor. Your videos, captions,
projects, and settings are processed **entirely on your device**. We do not
operate servers, do not create accounts, do not use analytics, do not show
ads, and do not track you across apps or websites.

## Information we do not collect

- No account or registration information.
- No email addresses or contact details.
- No usage analytics, crash reports sent to us, or telemetry.
- No advertising identifiers (IDFA/GAID) and no cross-app tracking.
- No location data.
- We do not sell, rent, or share any personal information, because we do not
  collect any.

## Data stored on your device

The app stores locally on your device:

- **Projects and captions** in a local database (Isar), including the videos
  you import and any caption/subtitle files you create.
- **Settings** such as language preferences and processing options.
- **Log files** written for troubleshooting. These never leave your device.

You can delete all of this data by deleting the app or its data folder.

## Downloads made by the app

To enable offline AI transcription and video rendering, the app may download
files from third-party hosts:

- **AI transcription models** (Whisper) from Hugging Face
  (`huggingface.co`).
- **FFmpeg / whisper-cli binaries** from their official or mirror hosts
  (e.g. `gyan.dev`, `evermeet.cx`, `johnvansickle.com`, GitHub Releases).
- **Emoji/font packs** from GitHub Releases.

These downloads happen only when you choose to install them, and the files are
stored locally. We do not receive any data about these downloads.

## Web version

The Web build loads open-source libraries (Whisper WASM and FFmpeg WASM) from
content delivery networks (CDNs) and may fetch AI model weights from Hugging
Face to run entirely in your browser. The Web version therefore requires an
active internet connection. No video content is uploaded — processing happens
in your browser.

## Permissions

- **Android/iOS**: access to your photo library / documents is used only to
  let you pick video files to import and to save exported videos. The app does
  not access these without your action.
- **macOS**: sandboxed file access to folders you explicitly choose.

## Third-party software

CapStudio is open source under the GNU General Public License v3.0 and
integrates open-source libraries (FFmpeg, whisper.cpp, and others). See
`CREDITS.md` for attribution.

## Changes to this policy

We may update this policy. The current version is always available at the
location where you obtained the app.

## Contact

For questions about this policy, contact the app developer at the repository
where you obtained CapStudio.
