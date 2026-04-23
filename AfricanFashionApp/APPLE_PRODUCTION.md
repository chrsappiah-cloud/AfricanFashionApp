# Apple Production Documentation

This document defines the release workflow for `AfricanFashionApp` on iOS.

## 1) Prerequisites

- Xcode installed and signed in with the Apple Developer account.
- Team ID configured: `TM2WG7HH96`.
- Bundle ID: `wcs.AfricanFashionApp`.
- App Store Connect app created for this bundle ID.
- App Store Connect API key available (`.p8`) for automated uploads.

## 2) Asset Requirements (App Store Validation)

- App icon asset set: `Assets.xcassets/AppIcon.appiconset`
  - Must include required iPhone/iPad sizes.
  - Must include `ios-marketing` 1024x1024 icon.
  - 1024 icon **must be opaque** (no alpha channel).
- Launch image asset set: `Assets.xcassets/LaunchImage.imageset`
  - Uses `LaunchImage-2732.png`.

## 3) Build and Archive (Release)

Run from `/Applications/AfricanFashionApp`:

```bash
xcodebuild \
  -project "/Applications/AfricanFashionApp/AfricanFashionApp.xcodeproj" \
  -scheme "AfricanFashionApp" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "/tmp/AFA-Archive/AfricanFashionApp-signed-clean.xcarchive" \
  -derivedDataPath "/tmp/AFA-DerivedData" \
  BUILD_DIR="/tmp/AFA-Build" \
  archive
```

## 4) Export IPA

Create export options plist (App Store Connect):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>teamID</key>
  <string>TM2WG7HH96</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>uploadSymbols</key>
  <false/>
  <key>uploadBitcode</key>
  <false/>
  <key>compileBitcode</key>
  <false/>
</dict>
</plist>
```

Export:

```bash
xcodebuild -exportArchive \
  -allowProvisioningUpdates \
  -archivePath "/tmp/AFA-Archive/AfricanFashionApp-signed-clean.xcarchive" \
  -exportPath "/tmp/AFA-Export" \
  -exportOptionsPlist "/tmp/AFA-ExportOptions.plist"
```

Output IPA:

- `/tmp/AFA-Export/AfricanFashionApp.ipa`

## 5) Upload to App Store Connect

```bash
xcrun altool --upload-app \
  --type ios \
  -f "/tmp/AFA-Export/AfricanFashionApp.ipa" \
  --apiKey "<API_KEY_ID>" \
  --apiIssuer "<API_ISSUER_ID>"
```

Successful upload returns a Delivery UUID.

## 6) Post-Upload Checklist

- Wait for build processing in App Store Connect.
- Add release notes for TestFlight.
- Assign internal testers first.
- Complete compliance/export questions.
- Submit app version for review.

## 7) Common Failures and Fixes

- `No Team Found in Archive`
  - Archive was unsigned. Re-archive with signing enabled.
- `No profiles for '<bundle-id>' were found`
  - Use `-allowProvisioningUpdates` and verify account/team access.
- `CFBundleIconName missing` or missing icon sizes
  - Ensure complete `AppIcon.appiconset` entries and files.
- `Invalid large app icon ... can't be transparent`
  - Regenerate 1024 icon as opaque (remove alpha channel).
- `Copy failed` during export (rsync symbols step)
  - Set `<key>uploadSymbols</key><false/>` in export options.
- `No space left on device`
  - Clear `~/Library/Developer/Xcode/DerivedData` and old simulator data.

## 8) Manual Simulator Test (Pre-Release)

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
