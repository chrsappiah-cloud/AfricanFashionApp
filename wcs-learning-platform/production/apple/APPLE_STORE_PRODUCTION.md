# WCS Platform Apple Store Production Process

This document defines a practical App Store production workflow for `wcs-learning-platform`.

## 1) Asset Pack Location

- App icon set: `production/apple/AppIcon.appiconset`
- Promotional images: `production/apple/promotional`
- App Store screenshot templates: `production/apple/promotional/app-store-screenshots`

## 2) Asset Checklist

- `AppIcon-1024.png` must be opaque (no alpha)
- Include complete iPhone/iPad icon sizes through `Contents.json`
- Prepare at least 3-6 App Store screenshots per device family
- Keep promotional exports in PNG for quality-safe delivery

## 3) iOS App Shell (Implemented)

A native SwiftUI wrapper loads the Next.js web app in a `WKWebView`. Default URL resolution:

1. UserDefaults `wcs_platform_base_url` (runtime override, e.g. from a debug menu or scheme argument)
2. Info.plist `WCSPlatformBaseURL` (set a production or staging `https://` URL before archiving)
3. `http://127.0.0.1:3000` (local dev; Simulator reaches the Mac host)

The in-app **reload** control (top-right) calls `reload()` on the web view if the first paint was empty before the dev server finished starting.

- Xcode project: `apps/ios/WCSPlatform/WCSPlatform.xcodeproj`
- Bundle ID: `com.wcs.learning.platform`
- `ITSAppUsesNonExemptEncryption` is set to `false` for standard export compliance (adjust if you add custom encryption).
- `PrivacyInfo.xcprivacy` documents UserDefaults access (`CA92.1`) used for optional URL override.
- Web loads show a **progress** overlay; failures show **Try again** with the resolved base URL.

Run the web app, then build or run the iOS target from Xcode:

```bash
pnpm --filter web dev
```

Open `WCSPlatform.xcodeproj`, choose an iPhone Simulator, and run.

## 4) Other Mobile Wrappers (Alternatives)

- Option B: React Native/Expo app under `apps/mobile`
- Option C: Capacitor wrapper for a web-based mobile shell

## 5) If Using Xcode Native Build

1. Add icons to `Assets.xcassets/AppIcon.appiconset`
2. Configure:
   - Bundle ID
   - Team ID
   - Signing certificates/profiles
3. Archive:

```bash
xcodebuild \
  -project "<PATH_TO_XCODEPROJ>" \
  -scheme "<SCHEME_NAME>" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "/tmp/WCS-Archive/WCS.xcarchive" \
  archive
```

4. Export IPA:

```bash
xcodebuild -exportArchive \
  -archivePath "/tmp/WCS-Archive/WCS.xcarchive" \
  -exportPath "/tmp/WCS-Export" \
  -exportOptionsPlist "/tmp/WCS-ExportOptions.plist"
```

## 6) Upload to App Store Connect

Use Transporter app or CLI:

```bash
xcrun altool --upload-app \
  --type ios \
  -f "/tmp/WCS-Export/<APP_NAME>.ipa" \
  --apiKey "<API_KEY_ID>" \
  --apiIssuer "<API_ISSUER_ID>"
```

## 7) App Store Listing Materials

Use the generated promotional assets for:

- App Store media planning
- Press/social launch
- Screenshot overlays and campaign adaptation

Recommended first copy set:
- Title: `WCS Learning Platform`
- Subtitle: `Learn. Build. Scale.`
- Promo text: `Future-ready learning for creators, teams, and professionals.`

## 8) Final Pre-Submission QA

- Install and run on physical iPhone
- Verify sign-in, purchase/subscription, and video playback flows
- Validate crash-free startup and offline handling
- Ensure policy pages: Privacy Policy and Terms are accessible
- Confirm app metadata, age rating, and compliance questions
