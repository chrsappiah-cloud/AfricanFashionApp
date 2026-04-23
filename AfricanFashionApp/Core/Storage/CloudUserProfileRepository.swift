//
//  CloudUserProfileRepository.swift
//  AfricanFashionApp
//

import Foundation
import SwiftData

enum CloudUserProfileRepository {
    static func upsertPrimary(appState: AppState, into context: ModelContext) throws {
        let targetKey = CloudScopeKeys.userProfile
        var descriptor = FetchDescriptor<CloudUserProfile>(
            predicate: #Predicate { $0.scopeKey == targetKey },
            sortBy: []
        )
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            apply(appState: appState, to: existing)
        } else {
            let row = CloudUserProfile(
                scopeKey: targetKey,
                cloudIdentityUUIDString: appState.cloudIdentityUUID.uuidString,
                displayName: appState.profileDisplayName,
                email: appState.profileEmail,
                regionFocus: appState.regionFocus,
                stylePreferencesNote: appState.stylePreferencesNote,
                hasCompletedOnboarding: appState.hasCompletedOnboarding,
                isAuthenticated: appState.isAuthenticated
            )
            context.insert(row)
        }
        try context.save()
    }

    private static func apply(appState: AppState, to profile: CloudUserProfile) {
        profile.cloudIdentityUUIDString = appState.cloudIdentityUUID.uuidString
        profile.displayName = appState.profileDisplayName
        profile.email = appState.profileEmail
        profile.regionFocus = appState.regionFocus
        profile.stylePreferencesNote = appState.stylePreferencesNote
        profile.hasCompletedOnboarding = appState.hasCompletedOnboarding
        profile.isAuthenticated = appState.isAuthenticated
        profile.updatedAt = .now
    }
}
