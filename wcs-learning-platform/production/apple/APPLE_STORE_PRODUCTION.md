# WCS Platform — Apple App Store production

Deployment runbook for the **WCS Platform** iOS app (`WKWebView` shell) in this monorepo. **App Review copy** for App Store Connect is in **`APP_STORE_REVIEW.md`**.

---

## 1) Project identifiers

| Item | Value |
|------|--------|
| Xcode project | `wcs-learning-platform/apps/ios/WCSPlatform/WCSPlatform.xcodeproj` |
| Scheme | `WCSPlatform` |
| Bundle ID | `com.wcs.learning.platform` |
| Team ID (signing) | `TM2WG7HH96` |
| Export options plist | `wcs-learning-platform/production/apple/ExportOptions-appstore.plist` |
| Privacy manifest | `WCSPlatform/PrivacyInfo.xcprivacy` |

---

## 2) Creative assets (this repo)

| Asset | Path |
|-------|------|
| App icons (all sizes + 1024 marketing) | `apps/ios/.../Assets.xcassets/AppIcon.appiconset/` and duplicate set `production/apple/AppIcon.appiconset/` |
| Hero (2732×2048) | `production/apple/promotional/Apple-Hero-2732x2048.png` |
| Social (1200×630) | `production/apple/promotional/Social-Post-1200x630.png` |
| Story (1080×1920) | `production/apple/promotional/Story-1080x1920.png` |
| Poster (2048×2732) | `production/apple/promotional/Poster-2048x2732.png` |
| App Store screenshot templates (1290×2796) | `production/apple/promotional/app-store-screenshots/iPhone-1290x2796-1.png` … `-4.png` |

**App Store icon rule:** `AppIcon-1024.png` must be **opaque** (no alpha). Regenerate from a square master if validation fails.

**Launch screen:** `LaunchScreenBackground` color in `Assets.xcassets` matches the in-app web chrome; `Info.plist` `UILaunchScreen` references `UIColorName` `LaunchScreenBackground`.

---

## 3) Before you archive (critical)

1. Set **`WCSPlatformBaseURL`** in `WCSPlatform/Info.plist` to your **production HTTPS** root (e.g. `https://learn.example.com/`). An empty value falls back to `http://127.0.0.1:3000`, which is **not** acceptable for an App Store build.
2. Confirm the hosted site is live, TLS-valid, and matches App Review notes in **`APP_STORE_REVIEW.md`**.
3. Bump **`CURRENT_PROJECT_VERSION`** in Xcode for each new upload if the version string is unchanged.

---

## 4) App Store Connect (first time)

1. Register App ID `com.wcs.learning.platform` with required capabilities.
2. Create the app in App Store Connect with the same bundle ID.
3. Complete **Agreements, Tax, and Banking** if you sell or use IAP.
4. Fill **App Privacy** to match data collected by the **embedded website** and native shell (`UserDefaults` for optional URL override is declared in `PrivacyInfo.xcprivacy`).

---

## 5) Archive and upload (Xcode)

1. Open `WCSPlatform.xcodeproj`.
2. Destination: **Any iOS Device (arm64)**.
3. **Product → Archive** (Release).
4. **Distribute App → App Store Connect → Upload**.

---

## 6) CLI archive and export

From the monorepo root (`wcs-learning-platform`):

```bash
PROJ="$PWD/apps/ios/WCSPlatform/WCSPlatform.xcodeproj"
xcodebuild -project "$PROJ" -scheme "WCSPlatform" -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "/tmp/WCS-Archive/WCSPlatform.xcarchive" \
  archive
```

Export IPA (paths relative to monorepo root):

```bash
xcodebuild -exportArchive \
  -allowProvisioningUpdates \
  -archivePath "/tmp/WCS-Archive/WCSPlatform.xcarchive" \
  -exportPath "/tmp/WCS-Export" \
  -exportOptionsPlist "$PWD/production/apple/ExportOptions-appstore.plist"
```

Upload with **Transporter** or Xcode Organizer. **`altool`** is deprecated.

---

## 7) Local development (web + simulator)

```bash
pnpm --filter web dev
```

Open the Xcode project, run on an **iPhone Simulator**; the shell can load `http://127.0.0.1:3000` when `WCSPlatformBaseURL` is unset.

---

## 8) Listing copy (starter)

| Field | Suggested text |
|-------|----------------|
| Title | WCS Learning Platform |
| Subtitle | Learn. Build. Scale. |
| Promotional text | Future-ready learning for creators, teams, and professionals. |

Refine with marketing; keep within App Store character limits.

---

## 9) Pre-submission QA

- Physical device: cold launch, reload, sign-in (if any), media in web view.
- **Offline:** error UI and “Try again” behave sensibly.
- Privacy Policy and Terms URLs reachable from the embedded site.
- Screenshot set in Connect matches what reviewers see on current iPhones.

---

## 10) Troubleshooting

| Issue | Mitigation |
|-------|------------|
| Blank white screen in review | `WCSPlatformBaseURL` wrong or site down; verify TLS and paths. |
| ATS blocks content | Production must use HTTPS; exceptions are for localhost only. |
| Signing / team errors | Confirm Apple ID in Xcode and team `TM2WG7HH96`. |
| Export symbol step fails | Set `uploadSymbols` to `false` temporarily in `ExportOptions-appstore.plist`. |

---

## 11) Related

- Main African Fashion iOS runbook (separate app): `AfricanFashionApp/APPLE_PRODUCTION.md` in the parent repo.
