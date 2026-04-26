# App Store submission — completion guide

This checklist covers **shipping binaries** and **finishing App Store Connect** for the two iOS products in this repository. Detailed build commands live in **`AfricanFashionApp/APPLE_PRODUCTION.md`** (native marketplace app) and **`wcs-learning-platform/production/apple/APPLE_STORE_PRODUCTION.md`** (WCS `WKWebView` shell).

**Important:** Submitting to Apple **cannot** be completed from a headless agent. You must sign in to Xcode (or use Transporter with a valid IPA) with an account that has **App Manager** or **Admin** access on team **TM2WG7HH96**.

---

## 0) Before you start (both apps)

- [ ] Apple Developer Program membership is active.
- [ ] **Agreements, Tax, and Banking** are complete in [App Store Connect](https://appstoreconnect.apple.com) if you use paid apps, IAP, or subscriptions.
- [ ] Each bundle ID exists under **Certificates, Identifiers & Profiles** and has a matching **App Store Connect** app record.

---

## 1) AfricanFashionApp (`wcs.AfricanFashionApp`)

| Check | Action |
|--------|--------|
| Version / build | **Version** `1.0.0`, **Build** `4` (in Xcode target **General** or `project.pbxproj`). Increase build again if this build was already uploaded. |
| Signing | Xcode → target **Signing & Capabilities** → Team **TM2WG7HH96**, automatic signing on. |
| Production APIs | Confirm production URLs / env in `App/AppConfiguration.swift` and any scheme **Environment Variables** for release. |
| Icons / privacy | Opaque `AppIcon-1024`; `PrivacyInfo.xcprivacy` accurate. |
| Archive | **Product → Archive** with destination **Any iOS Device (arm64)**. |
| Upload | Organizer → **Distribute App** → **App Store Connect** → **Upload**. |
| Export IPA (optional) | Use **`ExportOptions-appstore.plist`** at repo root; see `APPLE_PRODUCTION.md` §7. |

---

## 2) WCS Platform (`com.wcs.learning.platform`)

| Check | Action |
|--------|--------|
| **Blocker** | Set **`WCSPlatformBaseURL`** in `wcs-learning-platform/apps/ios/WCSPlatform/WCSPlatform/Info.plist` to your live **HTTPS** site root (trailing slash if required). **Do not ship** with an empty key (review build would open `http://127.0.0.1:3000`). |
| Version / build | **Version** `1.0.0`, **Build** `3` (or higher if already used in Connect). |
| Review notes | Paste from **`wcs-learning-platform/production/apple/APP_STORE_REVIEW.md`**; fill bracketed placeholders (demo URL, credentials). |
| Signing | Same team **TM2WG7HH96**; archive from `WCSPlatform.xcodeproj`. |
| Upload | Same Organizer flow as above. |
| Export IPA (optional) | **`wcs-learning-platform/production/apple/ExportOptions-appstore.plist`**. |

---

## 3) App Store Connect (after each upload)

1. Open **App Store Connect** → **My Apps** → select the app.
2. Wait until the build leaves **Processing** and shows **Ready to Submit** (resolve any email from Apple about missing compliance first).
3. **App Store** tab → select or create the version (e.g. `1.0.0`) → **+** next to **Build** → pick the new build.
4. Complete **required** metadata: screenshots, description, keywords, support URL, **App Privacy**, age rating, **Export compliance** (usually matches `ITSAppUsesNonExemptEncryption` in the binary).
5. **App Review Information**: contact phone, sign-in instructions if needed.
6. **Save**, then **Add for Review** / **Submit to App Review**.

---

## 4) TestFlight (optional, recommended first)

- Add internal testers, install from TestFlight, smoke-test on a **physical device**.
- For external testers, submit the build for **Beta App Review** when prompted.

---

## 5) After Apple approves

- Choose **Automatically release** or **Manually release this version**.
- Optional: **Phased release** for gradual rollout.

---

## 6) If a submission is rejected

- Read **Resolution Center** in App Store Connect.
- Fix issues, **increment the build number** (and version if needed), create a **new archive**, upload again, reattach the build to the same or new version, and resubmit.

---

## 7) Reference files

| File | Use |
|------|-----|
| `AfricanFashionApp/LAUNCH_MATERIALS.md` | Listing copy for AfricanFashionApp |
| `AfricanFashionApp/APPLE_PRODUCTION.md` | Full AfricanFashionApp deploy runbook |
| `wcs-learning-platform/production/apple/APPLE_STORE_PRODUCTION.md` | WCS deploy runbook + asset paths |
| `wcs-learning-platform/production/apple/APP_STORE_REVIEW.md` | WCS reviewer notes template |
