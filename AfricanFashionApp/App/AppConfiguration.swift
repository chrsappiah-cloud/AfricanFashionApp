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
