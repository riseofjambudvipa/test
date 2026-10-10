---
name: ffmpeg-pipeline
description: >-
  Architectural guide and execution runbook for CapStudio's video processing pipeline:
  hardware acceleration probing, complex filter construction, ASS subtitle burning,
  aspect ratio reframing, and audio mastering.
---

# FFmpeg Video & Audio Pipeline in CapStudio

CapStudio relies on static FFmpeg 7.x binaries and native bindings to perform video trimming, caption burning, multi-track audio mixing, and smart aspect ratio conversion.

## Platform Execution Engines

CapStudio dynamically selects the optimal execution engine at runtime:

1. **Desktop (`FfmpegDesktopExecution` in `lib/features/exporter/data/ffmpeg_desktop_execution.dart`)**:
   - Executes the bundled static `ffmpeg` executable directly as an asynchronous OS subprocess via `Process.start`.
   - Parses stderr progress line-by-line (`frame=`, `fps=`, `time=`, `bitrate=`, `speed=`) to compute real-time rendering ETA.
   - FFmpeg binary lookup order: `AppDirs.bin/ffmpeg` → project release bundle `bin/ffmpeg` → system `PATH`.
2. **Mobile (`FfmpegMobileExecution` in `lib/features/exporter/data/ffmpeg_mobile_execution.dart`)**:
   - Uses `ffmpeg_kit_flutter_new` native C/C++ mobile wrapper.
   - Binds directly into Android NDK `.so` libraries and iOS frameworks.
   - Employs `FFmpegKitConfig.enableStatisticsCallback` for progress reporting.

## Hardware Acceleration Detection

Before rendering, `FfmpegManager.probeHardwareEncoders()` executes a fast probe to discover GPU acceleration:

| Hardware Engine | Flag | OS | Priority |
| :--- | :--- | :--- | :--- |
| **NVIDIA NVENC** | `h264_nvenc`, `hevc_nvenc` | Windows, Linux | High (Fastest) |
| **Apple VideoToolbox** | `h264_videotoolbox`, `hevc_videotoolbox` | macOS, iOS | High (Metal hardware) |
| **Intel QuickSync (QSV)** | `h264_qsv`, `hevc_qsv` | Windows, Linux | High |
| **VAAPI** | `h264_vaapi` | Linux | Medium |
| **AMD AMF** | `h264_amf` | Windows | High |
| **Software CPU (libx264)** | `libx264 -preset veryfast` | All platforms | Fallback |

## Complex Filter Graph (`FfmpegFilters`)

When exporting a project, `FfmpegFilters.buildFilterComplexSlow()` generates a unified `-filter_complex` pipeline:

```
[0:v] trim & setpts -> scale & pad (Aspect Reframe) -> [v_base]
[v_base] ass=subtitles.ass (Caption Overlay) -> [v_sub]
[v_sub] overlay (Watermarks / Logos / B-Roll) -> [v_out]

[0:a] atrim & asetpts -> volume/loudnorm/eq -> [a_base]
[1:a] sfx audio mixing -> [a_sfx]
[a_base][a_sfx] amix=inputs=2 -> [a_out]
```

### 1. Smart Aspect Ratio Reframing
- **9:16 Vertical Shorts**:
  ```
  scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920
  ```
- **16:9 Landscape Video**:
  ```
  scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2
  ```
- **1:1 Square (Instagram/LinkedIn)**:
  ```
  scale=1080:1080:force_original_aspect_ratio=increase,crop=1080:1080
  ```

### 2. Audio Mastering Standards
- **Loudness Normalization**: EBU R128 standard target `-14 LUFS` (optimal for YouTube, TikTok, Reels):
  ```
  loudnorm=I=-14:TP=-1.5:LRA=11
  ```
- **3-Band Parametric EQ**: Vocal clarity enhancement (boost 2.5 kHz presence, high-pass rumble filter < 80 Hz):
  ```
  highpass=f=80,equalizer=f=2500:t=q:w=1.0:g=3
  ```
- **Silence Stripping**: Detects silent intervals (`silencedetect=noise=-30dB:d=0.5`) and generates split trim points.

## Font Resolution for Subtitles
- On desktop, `FfmpegFontPreparer` extracts required fonts to `AppDirs.fonts` and sets `fontsdir` in the ASS filter:
  ```
  ass=subtitles.ass:fontsdir='/path/to/fonts'
  ```
- Before accessing `AppDirs.fonts`, always check `AppDirs.isInitialized` to avoid `LateInitializationError` in unit tests.
