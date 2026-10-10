# Microsoft Store `runFullTrust` Capability Justification

*Application Name:* CapStudio  
*Package Identity:* `CapStudio.VideoCaptioning`  
*Capability Declared:* `runFullTrust` (`<rescap:Capability Name="runFullTrust"/>`)  
*Target Reviewer:* Microsoft Partner Center App Certification Team  

---

## 1. Executive Summary

CapStudio is a professional desktop video editing and automated subtitle generation suite built using Flutter and native Windows C++ APIs. It enables content creators, podcasters, and video editors to generate high-precision animated captions completely offline on their Windows PC.

CapStudio declares the restricted capability `runFullTrust` within its MSIX package manifest (`AppxManifest.xml`). This document provides the technical justification required by Microsoft Store Certification Policy 10.2.

---

## 2. Technical Reasons Requiring `runFullTrust`

### 2.1 Spawning Bundled Native CLI Child Processes (`ffmpeg.exe` & `whisper-cli.exe`)
- **Video Decoding & Encoding:** CapStudio bundles and spawns a static build of FFmpeg (`ffmpeg.exe` / `ffprobe.exe`) via `System.Diagnostics.Process` / Dart `Process.start` to perform hardware-accelerated video decoding, audio extraction, video filtering, and video rendering (using NVIDIA NVENC, Intel QuickSync, or AMD AMF).
- **Offline AI Speech Recognition:** CapStudio executes an optimized local speech recognition binary (`whisper-cli.exe`) or native C++ DLLs to transcribe video audio tracks directly against GGML model weights.
- **Sandboxed UWP Limitations:** Sandboxed UWP/AppContainer environments restrict the creation of unrestricted native Win32 child processes and pipes, which prevents standard multimedia utilities like FFmpeg from functioning.

### 2.2 Unrestricted Direct File System I/O for Large Video Files
- Video creators frequently work with 4K and 8K video files stored across multiple internal and external storage drives (e.g. `D:\Footage`, external NVMe SSDs).
- Standard UWP sandboxed file brokering degrades I/O throughput and fails to provide FFmpeg child processes with direct, low-latency POSIX file path access needed for real-time video scrubbing and rendering.

### 2.3 Dynamic Native Dynamic Library (FFI) Loading
- CapStudio binds directly to C++ audio processing and SQLite/Isar database libraries via Dart FFI (`DynamicLibrary.open`). Loading external native dynamic libraries requires full trust execution.

---

## 3. Security and Privacy Assurances

1. **100% Offline Processing:**
   - All video rendering, audio processing, and AI speech recognition are performed entirely locally on the user's PC.
   - No user media files or transcriptions are transmitted over the internet.
2. **No Background Services:**
   - CapStudio does not install Windows services, background daemons, or startup registry hooks.
3. **Clean Uninstallation:**
   - Packaged as an MSIX application, CapStudio leaves no orphaned files, registry keys, or background processes upon uninstallation.
4. **Code Signed:**
   - The binaries and installer package are digitally signed with a verified Authenticode certificate.
