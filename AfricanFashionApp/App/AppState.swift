//
//  AppState.swift
//  AfricanFashionApp
//

import Combine
import Foundation
import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case studio
    case catalog
    case discussion
    case cart
    case wishlist
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .studio: "Studio"
        case .catalog: "Catalog"
        case .discussion: "Discussion"
        case .cart: "Cart"
        case .wishlist: "Saved"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "sparkles"
        case .studio: "wand.and.stars"
        case .catalog: "square.grid.2x2"
        case .discussion: "bubble.left.and.bubble.right"
        case .cart: "bag"
        case .wishlist: "heart"
        case .profile: "person.crop.circle"
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: AppTab = .home
    @Published var isAuthenticated = false
    @Published var hasCompletedOnboarding: Bool
    @Published var profileDisplayName: String
    @Published var profileEmail: String
    @Published var authAccessToken: String
    @Published var regionFocus: String
    @Published var stylePreferencesNote: String

    /// Stable per-installation id used to correlate Cloud rows before server auth.
    let cloudIdentityUUID: UUID

    init(userDefaults: UserDefaults = .standard) {
        let launchArguments = ProcessInfo.processInfo.arguments
        let shouldBypassOnboarding = launchArguments.contains("-uiTestingCompleteOnboarding")

        if shouldBypassOnboarding {
            userDefaults.set(true, forKey: AppStorageKeys.onboardingComplete)
        }

        hasCompletedOnboarding = shouldBypassOnboarding || userDefaults.bool(forKey: AppStorageKeys.onboardingComplete)
        if launchArguments.contains("-uiTestingOpenStudio") {
            selectedTab = .studio
        } else if launchArguments.contains("-uiTestingOpenProfile") {
            selectedTab = .profile
        }
        regionFocus = userDefaults.string(forKey: AppStorageKeys.regionFocus) ?? "West Africa"
        stylePreferencesNote = userDefaults.string(forKey: AppStorageKeys.stylePreferencesNote) ?? ""
        profileDisplayName = userDefaults.string(forKey: AppStorageKeys.profileDisplayName) ?? ""
        profileEmail = userDefaults.string(forKey: AppStorageKeys.profileEmail) ?? ""
        authAccessToken = userDefaults.string(forKey: AppStorageKeys.authAccessToken) ?? ""

        if let stored = userDefaults.string(forKey: AppStorageKeys.cloudIdentityUUID),
           let uuid = UUID(uuidString: stored) {
            cloudIdentityUUID = uuid
        } else {
            let uuid = UUID()
            userDefaults.set(uuid.uuidString, forKey: AppStorageKeys.cloudIdentityUUID)
            cloudIdentityUUID = uuid
        }
    }

    func markOnboardingComplete(
        regionFocus: String,
        styleNote: String,
        userDefaults: UserDefaults = .standard
    ) {
        self.regionFocus = regionFocus
        self.stylePreferencesNote = styleNote
        userDefaults.set(regionFocus, forKey: AppStorageKeys.regionFocus)
        userDefaults.set(styleNote, forKey: AppStorageKeys.stylePreferencesNote)
        userDefaults.set(true, forKey: AppStorageKeys.onboardingComplete)
        hasCompletedOnboarding = true
    }

    func applySignIn(
        email: String,
        displayName: String,
        accessToken: String,
        userDefaults: UserDefaults = .standard
    ) {
        profileEmail = email
        profileDisplayName = displayName
        authAccessToken = accessToken
        isAuthenticated = true
        userDefaults.set(email, forKey: AppStorageKeys.profileEmail)
        userDefaults.set(displayName, forKey: AppStorageKeys.profileDisplayName)
        userDefaults.set(accessToken, forKey: AppStorageKeys.authAccessToken)
    }
}
