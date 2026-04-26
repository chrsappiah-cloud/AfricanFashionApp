# Apple Production Documentation

This document defines the release workflow for `AfricanFashionApp` on iOS.

## 1) Prerequisites

- Xcode installed and signed in with the Apple Developer account.
- Team ID configured: `TM2WG7HH96`.
- Bundle ID: `wcs.AfricanFashionApp`.
- App Store Connect app created for this bundle ID.
- Optional: App Store Connect API key (`.p8`) for scripted uploads.

## 2) Asset and compliance (App Store validation)

- App icon asset set: `Assets.xcassets/AppIcon.appiconset`
  - Must include required iPhone/iPad sizes.
  - Must include `ios-marketing` 1024x1024 icon.
  - 1024 icon **must be opaque** (no alpha channel).
- Launch image asset set: `Assets.xcassets/LaunchImage.imageset`
  - Uses `LaunchImage-2732.png`.
- Privacy manifest: `PrivacyInfo.xcprivacy` (declares `UserDefaults` usage with reason `CA92.1`).

## 3) Recommended path: Xcode Organizer

1. Open `AfricanFashionApp.xcodeproj` in Xcode.
2. Select the **AfricanFashionApp** scheme and destination **Any iOS Device (arm64)**.
3. **Product → Archive** (uses **Release** automatically).
4. In the Organizer window: **Distribute App → App Store Connect → Upload** (or **Export** if you need an IPA file).
5. Follow signing prompts (Automatic is configured in the project).

This is the most reliable path for production signing and symbol upload.

## 4) Build and archive (CLI, Release)

Run from `/Applications/AfricanFashionApp`:

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

## 5) Export IPA (CLI)

Committed export options (App Store Connect, automatic signing, symbol upload enabled):

- `/Applications/AfricanFashionApp/ExportOptions-appstore.plist`

Export:

```bash
xcodebuild -exportArchive \
  -allowProvisioningUpdates \
  -archivePath "/tmp/AFA-Archive/AfricanFashionApp.xcarchive" \
  -exportPath "/tmp/AFA-Export" \
  -exportOptionsPlist "/Applications/AfricanFashionApp/ExportOptions-appstore.plist"
```

Output IPA:

- `/tmp/AFA-Export/AfricanFashionApp.ipa`

If export fails during symbol packaging, edit the plist and set `uploadSymbols` to `false`, then export again (see troubleshooting below).

## 6) Upload to App Store Connect

- **Preferred:** Xcode Organizer upload, or Apple’s **Transporter** app with the IPA.
- **Legacy CLI:** `xcrun altool --upload-app` (deprecated; remove from automation when migrating to Transporter or CI that uses the App Store Connect API).

Example `altool` pattern (only if you still rely on it):

```bash
xcrun altool --upload-app \
  --type ios \
  -f "/tmp/AFA-Export/AfricanFashionApp.ipa" \
  --apiKey "<API_KEY_ID>" \
  --apiIssuer "<API_ISSUER_ID>"
```

## 7) Post-upload checklist

- Wait for build processing in App Store Connect.
- Add release notes for TestFlight.
- Assign internal testers first.
- Complete compliance and export questions.
- Submit the app version for review.

## 8) Common failures and fixes

- `No Team Found in Archive`
  - Archive was unsigned. Re-archive with signing enabled and a valid development team.
- `No profiles for '<bundle-id>' were found`
  - Use `-allowProvisioningUpdates` and verify account/team access in Xcode.
- `CFBundleIconName missing` or missing icon sizes
  - Ensure complete `AppIcon.appiconset` entries and files.
- `Invalid large app icon ... can't be transparent`
  - Regenerate 1024 icon as opaque (remove alpha channel).
- `Copy failed` during export (rsync symbols step)
  - Set `uploadSymbols` to `false` in `ExportOptions-appstore.plist` for that export only.
- `No space left on device`
  - Clear `~/Library/Developer/Xcode/DerivedData` and old simulator data.
- Privacy manifest rejection
  - Extend `PrivacyInfo.xcprivacy` if new “required reason” APIs are used.

## 9) Manual simulator test (pre-release)

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

Then install and launch with `simctl`.
