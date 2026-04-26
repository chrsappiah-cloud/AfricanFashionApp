//
//  AppConfiguration.swift
//  AfricanFashionApp
//

import Foundation

enum AppEnvironment: String, CaseIterable, Identifiable {
    case development
    case staging
    case production

    var id: String { rawValue }

    var apiBaseURL: URL {
        if let override = ProcessInfo.processInfo.environment["AFRICANFASHION_API_BASE_URL"],
           let url = URL(string: override.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return url
        }
        return switch self {
        case .development:
            URL(string: "https://api.dev.africanfashion.example")!
        case .staging:
            URL(string: "https://api.staging.africanfashion.example")!
        case .production:
            URL(string: "https://api.africanfashion.example")!
        }
    }
}

struct AppConfiguration: Sendable {
    let environment: AppEnvironment

    private static let fallbackEnvironment: AppEnvironment = .production

    static let current: AppConfiguration = {
        if let override = ProcessInfo.processInfo.environment["AFRICANFASHION_APP_ENV"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(),
           let parsed = AppEnvironment(rawValue: override) {
            return AppConfiguration(environment: parsed)
        }
        return AppConfiguration(environment: fallbackEnvironment)
    }()

    /// Must match **iCloud** capability and the container in `AfricanFashionApp.entitlements`.
    static let cloudKitContainerIdentifier = "iCloud.wcs.AfricanFashionApp"
}

// MARK: - Outbound brand & payments (environment-driven)

/// Social, checkout, and admin dashboard URLs — supply via Xcode scheme **Environment Variables** or CI exports.
struct BrandOutboundLinks: Sendable {
    let instagramURL: URL?
    let tiktokURL: URL?
    let facebookURL: URL?
    let xURL: URL?
    let youtubeChannelURL: URL?
    let linkedInURL: URL?
    /// Hosted card checkout (Stripe Checkout, Payment Link, etc.).
    let membershipCardCheckoutURL: URL?
    /// PSP dashboard for Connect / payout accounts (administrators).
    let merchantFinancialDashboardURL: URL?
    let appleSubscriptionsMarketingURL: URL?

    static let current: BrandOutboundLinks = {
        func envURL(_ key: String) -> URL? {
            guard let raw = ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !raw.isEmpty,
                  let url = URL(string: raw),
                  URLValidator.isAllowedHTTPURL(url)
            else { return nil }
            return url
        }

        return BrandOutboundLinks(
            instagramURL: envURL("SOCIAL_INSTAGRAM_URL"),
            tiktokURL: envURL("SOCIAL_TIKTOK_URL"),
            facebookURL: envURL("SOCIAL_FACEBOOK_URL"),
            xURL: envURL("SOCIAL_X_URL"),
            youtubeChannelURL: envURL("SOCIAL_YOUTUBE_CHANNEL_URL"),
            linkedInURL: envURL("SOCIAL_LINKEDIN_URL"),
            membershipCardCheckoutURL: envURL("STRIPE_MEMBERSHIP_CHECKOUT_URL"),
            merchantFinancialDashboardURL: envURL("ADMIN_MERCHANT_DASHBOARD_URL"),
            appleSubscriptionsMarketingURL: envURL("APPLE_IAP_GUIDE_URL")
                ?? URL(string: "https://developer.apple.com/in-app-purchase/")
        )
    }()

    var socialPairs: [(label: String, url: URL)] {
        var out: [(String, URL)] = []
        if let instagramURL { out.append(("Instagram", instagramURL)) }
        if let tiktokURL { out.append(("TikTok", tiktokURL)) }
        if let facebookURL { out.append(("Facebook", facebookURL)) }
        if let xURL { out.append(("X", xURL)) }
        if let youtubeChannelURL { out.append(("YouTube", youtubeChannelURL)) }
        if let linkedInURL { out.append(("LinkedIn", linkedInURL)) }
        return out
    }
}
