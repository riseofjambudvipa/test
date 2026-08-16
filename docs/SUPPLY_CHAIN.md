# Supply Chain Status (audited)

Last audited: Aug 2026. Every binary the app downloads is listed below with its
source, verification, and live-check status.

## What's verified and pinned

| Artifact | Source | Verification | Live check |
|---|---|---|---|
| whisper-cli (Windows, AVX2) | `ggml-org/whisper.cpp` v1.8.4 official release | Pinned SHA-256 | ✅ hash matches live artifact |
| whisper-cli (Windows, no-AVX2) | CapStudio GitHub release v0.0.1 | Pinned SHA-256 | ✅ hash matches live artifact + release `.sha256` |
| FFmpeg (Windows) | gyan.dev release-essentials | Dynamic `.sha256` fetch | ✅ URL + companion file live |
| FFmpeg (macOS) | evermeet.cx ffmpeg-7.1 | Pinned SHA-256 | ✅ hash matches live artifact |
| FFmpeg (Linux) | johnvansickle.com static | Dynamic `.md5` fetch | ✅ URL + companion file live |
| Whisper models (9) | HuggingFace + hf-mirror fallback | Pinned SHA-1 each | ✅ 8/8 cross-checked vs official list; `medium.en` added |
| Emoji/asset packs (6) | CapStudio GitHub release v0.0.1 | Pinned SHA-256 in manifest | ✅ (hashes baked into asset_manifest) |

All downloads are HTTPS. Extraction rejects path traversal (Zip Slip / tar
traversal), and executables are validated by magic bytes (PE / ELF / Mach-O)
plus Authenticode / codesign checks where available.

## Fixed in this audit

1. **`medium.en` model was missing from the SHA-1 map** — its downloads silently
   skipped integrity verification. SHA-1 now pinned (from whisper.cpp's
   official published list).
2. **Fail-closed checksums** — `_verifyChecksum` previously logged a warning and
   PASSED when no checksum was configured, installing unverified binaries.
   It now refuses the install.
3. **macOS whisper graceful fallback** — the macOS whisper URL 404s (asset was
   never uploaded to the release). macOS now shows actionable manual-install
   steps (Homebrew or source build) instead of a generic error, matching what
   Linux already did.

## Known gaps / action items

- **macOS + Linux whisper-cli auto-install is broken today**: the URLs point to
  `whisper-cli-mac-universal.zip` / `whisper-cli-linux-x64.zip`, which do NOT
  exist in the CapStudio GitHub release v0.0.1. Both now degrade gracefully to
  manual steps, but to restore one-click install on those platforms you must:
  1. Build and upload the binaries to a GitHub release (pinned tag).
  2. Pin their SHA-256 in `binary_downloader_service.dart` (near
     `_windowsWhisperCliAvxSha256`). Fail-closed means an unverified build will
     be refused — that's intentional.
- **Supply-chain ownership**: FFmpeg binaries still come from third-party
  mirrors (gyan.dev, evermeet.cx, johnvansickle.com) and asset packs/whisper
  CLI from a personal GitHub release. None of these are owned by the app; if a
  mirror dies, that platform loses one-click install. Bundling FFmpeg inside
  the app packages (workstream 6) removes the mirror dependency for macOS/Linux
  entirely.

## Web app shell (platform-gaps pass)

The web build previously had two problems: it loaded runtime scripts from
CDNs, **and it did not compile at all** (the Isar-generated schemas contained
64-bit integer literals that dart2js rejects). Both are fixed:

- **Runtime scripts vendored locally** in `web/vendor/` — transformers.min.js,
  ffmpeg.min.js, ffmpeg-core.js + .wasm — so the app shell needs no CDN.
  `ffmpeg_web.js` falls back to the unpkg CDN mirror if a local core is
  missing from a stale build. Whisper model weights (75MB–1.5GB) are still
  fetched on demand from HuggingFace — too large to bundle; transcription is
  inherently online on web.
- **Schema literals made dart2js-compatible**: `project.g.dart` / `word.g.dart`
  now express their 64-bit schema ids via `int.parse('...')` with non-const
  declarations. On native this is byte-exact (verified equal to the original
  const literal); on web Isar is not used (in-memory storage), so rounding is
  harmless. The `int.parse` patch lives in the committed `.g.dart` files — if
  you ever re-run `build_runner`, regenerate the patch (9 literals across the
  two files) or web breaks again.
- **Isar migrated to the maintained `isar_community` fork** (3.3.2) — same
  API, keeps native behavior, and the upstream `isar` package is archived.

## Policy (keep it true)

- Every download must have a pinned checksum (SHA-256 preferred) or a live
  checksum fetched over HTTPS from the same origin.
- Never relax `_verifyChecksum` back to pass-on-empty. If a platform has no
  checksum, prefer a manual-install fallback over an unverified install.
- When bumping a pinned version (e.g., FFmpeg 7.1 → 8.x), update the matching
  hash in the same commit — the code comments call this out at each constant.
