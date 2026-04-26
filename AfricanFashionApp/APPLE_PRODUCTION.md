# Apple App Store deployment — AfricanFashionApp

This document is the **deployment runbook** for shipping **AfricanFashionApp** to TestFlight and the public App Store. For marketing copy (description, keywords, social posts), use **`LAUNCH_MATERIALS.md`** in the same folder. For the separate **WCS Learning** iOS shell (`WKWebView` + monorepo), see **`wcs-learning-platform/production/apple/APPLE_STORE_PRODUCTION.md`**.

---

## 1) Project identifiers (keep in sync everywhere)

| Item | Value |
|------|--------|
| Xcode project | `AfricanFashionApp.xcodeproj` (repo root: `/Applications/AfricanFashionApp`) |
| Scheme | `AfricanFashionApp` |
| Bundle ID | `wcs.AfricanFashionApp` |
| Apple Developer Team ID | `TM2WG7HH96` |
| Marketing version | `MARKETING_VERSION` in Xcode (user-facing **Version**) |
| Build number | `CURRENT_PROJECT_VERSION` in Xcode (must increase for each upload if version unchanged) |
| Export options plist | `/Applications/AfricanFashionApp/ExportOptions-appstore.plist` |
| Privacy manifest | `AfricanFashionApp/PrivacyInfo.xcprivacy` |
| Entitlements | `AfricanFashionApp/AfricanFashionApp.entitlements` (CloudKit container `iCloud.wcs.AfricanFashionApp`) |

---

## 2) First-time App Store Connect setup

Complete these **once** (or per new bundle ID) before uploads succeed end-to-end.

1. **Apple Developer** (developer.apple.com): register the App ID `wcs.AfricanFashionApp` with required capabilities (e.g. iCloud/CloudKit if used in the app).
2. **App Store Connect** (appstoreconnect.apple.com): **My Apps → +** create the app, matching bundle ID and SKU.
3. **Agreements, Tax, and Banking**: accept **Paid Applications** (or free-app equivalent) and provide tax/banking if you sell or use IAP.
4. **Users and Access**: invite internal testers (App Store Connect accounts on your team).
5. **App Privacy** questionnaire: answer data collection questions; answers should align with runtime behavior and **`PrivacyInfo.xcprivacy`**.

---

## 3) Versioning policy

- **Version** (`CFBundleShortVersionString` / `MARKETING_VERSION`): semantic marketing version (e.g. `1.0.0`, `1.1.0`). Bump when users should see a “new release.”
- **Build** (`CFBundleVersion` / `CURRENT_PROJECT_VERSION`): monotonically increasing integer for App Store Connect. **Each binary upload** must use a build number **not already used** for that version in App Store Connect.
- After changing only marketing strings or metadata (no new binary), you do **not** need a new build.

---

## 4) Pre-upload checklist

**Project / binary**

- [ ] Release configuration builds cleanly (Xcode or CLI).
- [ ] `AppIcon.appiconset` complete; **1024×1024** marketing icon is **opaque** (no alpha).
- [ ] `LaunchImage` / launch screen behaves on smallest and largest supported devices.
- [ ] `PrivacyInfo.xcprivacy` reflects any new **Required Reason API** usage.
- [ ] `Info.plist` usage strings (e.g. `NSPhotoLibraryUsageDescription`) match real features.
- [ ] `ITSAppUsesNonExemptEncryption` in `Info.plist`: set to `false` only if the app uses **no** custom non-exempt encryption (typical HTTPS/TLS-only apps). Change to `true` and document if you add proprietary crypto.
- [ ] Production API and outbound URLs: see `App/AppConfiguration.swift` and scheme environment variables; confirm production endpoints before release.

**App Store Connect (before or after upload)**

- [ ] Screenshots for required device sizes (Apple’s current specs are under **App Store → App Previews and Screenshots** in Help; update when Apple changes rules).
- [ ] App name, subtitle, description, keywords, support URL, marketing URL (see `LAUNCH_MATERIALS.md`).
- [ ] Age rating questionnaire completed.
- [ ] **Export compliance** questions answered (see §10).

---

## 5) Recommended path: Xcode Organizer (upload)

1. Open **`AfricanFashionApp.xcodeproj`** in Xcode.
2. Scheme **AfricanFashionApp**, destination **Any iOS Device (arm64)**.
3. **Product → Archive** (builds **Release**).
4. Organizer: **Distribute App → App Store Connect → Upload** (follow signing; Automatic signing is set in the project).
5. Wait for email/processing in App Store Connect (**Activity** tab).

This path handles signing and symbol upload with the fewest moving parts.

---

## 6) CLI: archive (Release)

From `/Applications/AfricanFashionApp`:

```bash
xcodebuild \
  -project "/Applications/AfricanFashionApp/AfricanFashionApp.xcodeproj" \
  -scheme "AfricanFashionApp" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "/tmp/AFA-Archive/AfricanFashionApp.xcarchive" \
  -derivedDataPath "/tmp/AFA-DerivedData" \
  BUILD_DIR="/tmp/AFA-Build" \
  archive
```

---

## 7) CLI: export IPA (App Store)

Committed plist:

- `/Applications/AfricanFashionApp/ExportOptions-appstore.plist`

```bash
xcodebuild -exportArchive \
  -allowProvisioningUpdates \
  -archivePath "/tmp/AFA-Archive/AfricanFashionApp.xcarchive" \
  -exportPath "/tmp/AFA-Export" \
  -exportOptionsPlist "/Applications/AfricanFashionApp/ExportOptions-appstore.plist"
```

**Output:** `/tmp/AFA-Export/AfricanFashionApp.ipa`

If export fails during symbol packaging, set `uploadSymbols` to `false` in that plist temporarily, export again, then restore if you want symbols on the next release.

---

## 8) Upload to App Store Connect

| Method | Notes |
|--------|--------|
| **Xcode Organizer** | Preferred after archiving on a signed-in Mac. |
| **Transporter** (Mac App Store) | Drag the `.ipa`; good for CI-produced IPAs. |
| **`xcrun altool --upload-app`** | Deprecated by Apple; migrate to Transporter or App Store Connect API when possible. |

Example `altool` (legacy only):

```bash
xcrun altool --upload-app \
  --type ios \
  -f "/tmp/AFA-Export/AfricanFashionApp.ipa" \
  --apiKey "<API_KEY_ID>" \
  --apiIssuer "<API_ISSUER_ID>"
```

---

## 9) After upload: attach build and complete the version

1. App Store Connect → your app → **TestFlight** or **App Store** tab.
2. Wait until the build shows **Processing**, then **Ready to Submit** (fix any compliance emails from Apple first).
3. Under the **App Store** version (e.g. 1.0.0), **+** select this build.
4. Fill **What’s New in This Version**, screenshots, and review contact/notes.
5. **Save**, then **Add for Review** / **Submit to App Review** when all blocking items are green.

---

## 10) Export compliance and encryption

- App Store Connect asks whether the app uses encryption. The project includes **`ITSAppUsesNonExemptEncryption`** in `Info.plist` when set (standard declaration for exempt-only use).
- If you introduce **non-exempt** encryption (custom algorithms, etc.), you must set the plist appropriately and may need **annual self-classification** or **CCATS** documentation per U.S. export rules—not covered here; involve legal/compliance.

---

## 11) TestFlight

1. Processing completes → build appears in **TestFlight**.
2. **Internal testing**: add internal testers (fast; no Beta App Review for many builds).
3. **External testing**: create a group, add testers, submit **Beta App Review** if required.
4. Collect crash and energy logs from TestFlight; dSYM upload (Organizer / export options) improves crash symbolication.

---

## 12) App Review submission and release

- **App Review Information**: sign-in demo account if the app requires login; add notes for reviewers (e.g. how to reach a paywalled screen).
- **Release**: after approval, choose **Manual** or **Automatic** release; optional **Phased Release** for gradual rollout.
- **Rejected builds**: read Resolution Center message, fix, bump **build** (and version if needed), re-upload.

---

## 13) App Privacy (nutrition labels) vs code

- **App Store Connect → App Privacy** describes data types sent off-device (linked to user, used for tracking, etc.).
- **`PrivacyInfo.xcprivacy`** declares certain **accessed APIs** (e.g. `UserDefaults` with reason `CA92.1`). They serve different purposes; keep both accurate when you add analytics, ads, or new SDKs.

---

## 14) Troubleshooting

| Symptom | Action |
|---------|--------|
| No team in archive | Sign in to Xcode with the correct Apple ID; set **Signing & Capabilities** team to `TM2WG7HH96`. |
| No provisioning profile | Enable **Automatically manage signing**; use `-allowProvisioningUpdates` on CLI. |
| Invalid / transparent 1024 icon | Replace with opaque PNG. |
| Privacy manifest rejection | Update `PrivacyInfo.xcprivacy` for any new required-reason APIs. |
| Export “Copy failed” / rsync symbols | Temporarily set `uploadSymbols` to `false` in `ExportOptions-appstore.plist`. |
| Disk full | Clear `~/Library/Developer/Xcode/DerivedData` and old simulators. |

---

## 15) Manual simulator build (pre-release smoke test)

```bash
xcodebuild \
  -project "/Applications/AfricanFashionApp/AfricanFashionApp.xcodeproj" \
  -scheme "AfricanFashionApp" \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -derivedDataPath "/tmp/AFA-SimDerived" \
  BUILD_DIR="/tmp/AFA-SimBuild" \
  build
```

Install/launch with **Xcode** or `xcrun simctl` as needed.

---

## 16) Related documentation

| Document | Purpose |
|----------|---------|
| `LAUNCH_MATERIALS.md` | App Store listing copy, TestFlight notes, social copy |
| `wcs-learning-platform/production/apple/APPLE_STORE_PRODUCTION.md` | WCS Platform iOS wrapper, assets, CLI export |
| `wcs-learning-platform/production/apple/APP_STORE_REVIEW.md` | Paste-up notes for App Store Connect reviewers (WCS) |
