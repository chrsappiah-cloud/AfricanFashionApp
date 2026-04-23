//
//  AfricanFashionAppTests.swift
//  AfricanFashionAppTests
//
//  Created by Christopher Appiah-Thompson  on 23/4/2026.
//

import Foundation
import Testing
@testable import AfricanFashionApp

struct AfricanFashionAppTests {

    @Test func appStateMarksOnboardingCompleteAndPersists() async throws {
        let suiteName = "AfricanFashionAppTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create isolated test UserDefaults suite.")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        let state = await MainActor.run { AppState(userDefaults: defaults) }
        #expect(await MainActor.run { state.hasCompletedOnboarding } == false)

        await MainActor.run {
            state.markOnboardingComplete(regionFocus: "Diaspora", styleNote: "Tailored minimalism", userDefaults: defaults)
        }

        #expect(await MainActor.run { state.hasCompletedOnboarding } == true)
        #expect(await MainActor.run { state.regionFocus } == "Diaspora")
        #expect(await MainActor.run { state.stylePreferencesNote } == "Tailored minimalism")
        #expect(defaults.bool(forKey: AppStorageKeys.onboardingComplete) == true)
    }

    @Test func appStateApplySignInStoresIdentityAndToken() async throws {
        let suiteName = "AfricanFashionAppTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create isolated test UserDefaults suite.")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        let state = await MainActor.run { AppState(userDefaults: defaults) }
        await MainActor.run {
            state.applySignIn(
                email: "wendy@example.com",
                displayName: "Wendy",
                accessToken: "token-123",
                userDefaults: defaults
            )
        }

        #expect(await MainActor.run { state.isAuthenticated } == true)
        #expect(await MainActor.run { state.profileEmail } == "wendy@example.com")
        #expect(await MainActor.run { state.profileDisplayName } == "Wendy")
        #expect(await MainActor.run { state.authAccessToken } == "token-123")
    }

    @Test func backendRetryPolicyHandlesTransientFailures() async throws {
        #expect(BackendAPI.shouldRetry(statusCode: 408))
        #expect(BackendAPI.shouldRetry(statusCode: 429))
        #expect(BackendAPI.shouldRetry(statusCode: 503))
        #expect(BackendAPI.shouldRetry(statusCode: 200) == false)
        #expect(BackendAPI.shouldRetry(statusCode: 404) == false)
    }

    @Test func backendAllowedHostsIncludesConfiguredAPIHost() async throws {
        let configuredHost = AppConfiguration.current.environment.apiBaseURL.host?.lowercased()
        #expect(configuredHost != nil)
        if let configuredHost {
            #expect(BackendAPI.allowedHosts.contains(configuredHost))
        }
    }

}
