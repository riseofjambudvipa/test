# CapStudio — Store Readiness

Everything needed to publish CapStudio to the app stores. **Monetization is
deliberately out of scope** — this doc assumes a free release; a payment layer
can be added later without changing the steps below.

---

## 0. Licensing decision — read this first ⚠️

CapStudio is **GPL-3.0** and links FFmpeg compiled with **libass** (GPL). This
matters for stores:

- ✅ **Publishing a GPL app to Google Play / App Store / MS Store is legal and
  common.** GPL allows redistribution (including paid), as long as you
  provide the source and license notices. The source is public in this repo.
- ⚠️ **Future monetization:** if you later sell a closed-source "premium" tier,
  GPL requires that every buyer also gets the source, and the whole app stays
  GPL. That is incompatible with a closed paid model.
- 🔀 **To go closed-source later**, the FFmpeg+libass pipeline must be replaced
  with an LGPL-compatible renderer (libass is the blocker — there is no LGPL
  drop-in for `.ass` burning). This is a significant engineering change and
  should be decided **before** deep monetization work, not after.

**Recommendation:** ship free as GPL now (fully store-legal). When you plan
monetization, evaluate the LGPL renderer swap as a separate project.

## 1. Global prerequisites

- [ ] Developer accounts:
  - Google Play Console — **$25 one-time**
  - Apple Developer Program — **$99/year**
  - Microsoft Partner Center — free tier or ~$19 (individual) / $99 (company)
- [ ] Host a privacy policy at a public URL. Draft: `docs/PRIVACY_POLICY.md`
      (publish it, e.g. GitHub Pages, and link it in every store listing).
- [ ] Host marketing assets: app icon (exists: `assets/images/logo.png`),
      feature graphic, screenshots (see per-store sizes below).
- [ ] Decide the **final store-facing name**. Currently `CapStudio`.
- [ ] Confirm bundle/package IDs (currently `com.capstudio.ai` everywhere —
      Android, iOS, macOS). **Do not change after first submission.**

## 2. Google Play (Android)

CI already produces `app-release.aab` (`build_android` job) and signs it via
the `KEYSTORE_*` secrets.

- [ ] **App signing:** generate a release keystore (`keytool`), store it
      safely, add the 4 `KEYSTORE_*` secrets to GitHub. Then either:
      - Enable **Play App Signing** and upload the AAB with the upload key, or
      - Keep the keystore as the signing key. **Never lose it.**
- [ ] **Data Safety form:** declare *no data collected*; note that
      user-selected files (videos) stay on device; internet is used only for
      optional model/binary downloads.
- [ ] **Content rating:** complete the questionnaire (no mature content).
- [ ] **Target API:** `targetSdk = 36` (already current — re-verify before
      release that it meets Play's requirement window).
- [ ] **64-bit:** `arm64-v8a` is in `abiFilters` — required, already OK.
- [ ] **Store listing:** description, 2 screenshots per phone size (6.5″ +
      5.5″), tablet screenshots, feature graphic (1024×500), icon.
- [ ] **App access / account deletion:** app has no accounts — answer
      "not applicable" on the form.
- [ ] Optional: `android:label` now reads from `strings.xml` (done) so the
      name can be localized later.

## 3. Apple App Store (iOS)

CI produces an unsigned `Runner.app` (`build_ios` job, `--no-codesign`).
Submission requires an Apple account with signing certs.

- [ ] **Certificates:** create a distribution certificate + provisioning
      profile in the Apple Developer portal; add them to the CI (or build
      locally via Xcode).
- [ ] **App Store Connect:** create the app record with bundle ID
      `com.capstudio.ai`.
- [ ] **Privacy labels:** answer "no data collected" — consistent with
      `ios/Runner/PrivacyInfo.xcprivacy` (no tracking, no collected data).
- [ ] **App Review notes:** describe local-first processing + that model/binary
      downloads come from Hugging Face / GitHub (helps reviewers understand
      the network usage).
- [ ] **Screenshots:** 6.7″ (iPhone 15 Pro Max), 6.5″, 5.5″ and iPad sizes,
      plus app preview optional.
- [ ] **Removed red flags (done):** `NSMicrophoneUsageDescription` (no mic
      feature) and `NSUserTrackingUsageDescription` (no tracking) are gone
      from `Info.plist`.
- [ ] **Deployment target:** iOS 16.0 — fine; note the app supports
      landscape + portrait.
- [ ] ⚠️ **`ffmpeg_kit_flutter_new` is upstream-discontinued.** It builds and
      ships today, but plan a migration (e.g. mobile FFmpeg via
      `ffmpeg-kit` alternatives or prebuilt FFmpeg libs) before relying on
      long-term App Store maintenance.

## 4. Microsoft Store (Windows)

MSIX packaging is already configured in `pubspec.yaml`.

- [ ] **Publisher identity:** create the app in Partner Center; replace the
      DEV cert block in `pubspec.yaml` with the Partner Center publisher /
      identity values (the commented template is already there) and run
      `dart run msix:create --store`.
- [ ] **Capabilities:** `runFullTrust` is required for launching the bundled
      ffmpeg/whisper processes but Microsoft asks for justification — be
      ready to explain it in the submission notes.
- [ ] **Signing:** Partner Center re-signs; local builds use the self-signed
      cert (`scripts/certificate/windows/`) — keep the password out of the
      repo (pass via `CAPSTUDIO_CERT_PASSWORD`).
- [ ] **SmartScreen:** for direct `.zip`/installer distribution outside the
      store, buy a code-signing certificate to avoid "Unknown publisher"
      warnings.
- [ ] **Listing:** description, screenshots (≥1 of 1366×768+), icon, and the
      privacy policy URL.

## 5. macOS

- [ ] **Direct distribution (.dmg):** CI builds `CapStudio.dmg` — needs
      **Developer ID Application certificate + notarization** before users can
      open it without warnings.
- [ ] **Mac App Store (optional):** create the app record, keep the sandbox +
      entitlements (already sandboxed), and submit the notarized build. Note
      the hardened-runtime exception `disable-library-validation` is allowed
      but will be reviewed.
- [ ] **Privacy policy + screenshots** also required here.

## 6. Web

Not a store target, but if you publish it:
- [ ] The PWA manifest (`web/manifest.json`) is complete.
- [ ] The web build needs internet (CDN scripts + model downloads) — make the
      landing page say so.

## 7. Release checklist (all platforms)

- [ ] `flutter analyze` clean, `flutter test` green (CI gates this).
- [ ] Version bump in `pubspec.yaml` (`1.0.0+1` → next) for each release.
- [ ] Update `docs/README.md` platform matrix if anything changes.
- [ ] Generate fresh screenshots from the released build.
- [ ] Publish the privacy policy and link it everywhere.
- [ ] Do a clean build from CI for each platform and smoke-test the artifact.
