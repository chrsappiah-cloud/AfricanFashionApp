//
//  CloudUserProfile.swift
//  AfricanFashionApp
//

import Foundation
import SwiftData

/// One row per iCloud user (private database), keyed by `scopeKey`.
/// Mirrors onboarding + sign-in snapshot for multi-device recovery — not a replacement for server auth.
@Model
final class CloudUserProfile {
    var scopeKey: String = ""
    var cloudIdentityUUIDString: String = ""
    var displayName: String = ""
    var email: String = ""
    var regionFocus: String = ""
    var stylePreferencesNote: String = ""
    var hasCompletedOnboarding: Bool = false
    var isAuthenticated: Bool = false
    var updatedAt: Date = Date()

    init(
        scopeKey: String = CloudScopeKeys.userProfile,
        cloudIdentityUUIDString: String,
        displayName: String,
        email: String,
        regionFocus: String,
        stylePreferencesNote: String,
        hasCompletedOnboarding: Bool,
        isAuthenticated: Bool,
        updatedAt: Date = .now
    ) {
        self.scopeKey = scopeKey
        self.cloudIdentityUUIDString = cloudIdentityUUIDString
        self.displayName = displayName
        self.email = email
        self.regionFocus = regionFocus
        self.stylePreferencesNote = stylePreferencesNote
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.isAuthenticated = isAuthenticated
        self.updatedAt = updatedAt
    }
}
