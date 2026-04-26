# App Store Review — WCS Platform (iOS)

Use this text in **App Review Information → Notes** in App Store Connect. Update bracketed values before submission.

## What the app is

WCS Platform is a **native SwiftUI shell** that loads the WCS Learning web experience in a **WKWebView**. The shipped binary does not embed the full Next.js bundle; it loads your hosted site over **HTTPS** in production.

## How reviewers should test

1. **Production URL (required before archive)**  
   Set `WCSPlatformBaseURL` in `Info.plist` to your live HTTPS base URL (include trailing path only if your site requires it), for example: `https://your-domain.example/`  
   Archive and upload **after** this value is set so the review build opens the real site.

2. **Optional overrides**  
   - Scheme environment variable or UserDefaults key `wcs_platform_base_url` can override the URL for internal testing (not needed for review if plist is correct).

3. **In-app controls**  
   - **Reload** (top-right) refreshes the web view if loading stalls.

4. **Local dev exceptions**  
   - `NSAppTransportSecurity` allows **localhost** and **127.0.0.1** HTTP for simulator/local development only. Production traffic should use **HTTPS** on your primary domain.

## Demo account (if your web app requires login)

- **URL:** [production sign-in URL]  
- **Username / email:** [reviewer account]  
- **Password:** [single-use or review password]  

If no login is required, state: “No account required for core browsing.”

## Subscriptions / purchases

[Describe IAP or web checkout used by the embedded site, or state “None in the native shell; payments occur on the website under separate terms.”]

## Export compliance

`ITSAppUsesNonExemptEncryption` is **false** (standard TLS only). Update if you add custom non-exempt cryptography.

## Contact

- **First name / phone:** [your contact]  
- **Monitor** email associated with App Store Connect during review.
