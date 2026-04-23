//
//  CloudKitAccountDiagnostics.swift
//  AfricanFashionApp
//

import CloudKit
import Combine
import SwiftUI

/// Surface iCloud / CloudKit account state for debugging and support (not a substitute for your commerce backend).
@MainActor
final class CloudKitAccountDiagnostics: ObservableObject {
    @Published private(set) var summary: String = "…"
    @Published private(set) var isChecking = true

    func refresh() async {
        isChecking = true
        defer { isChecking = false }
        let container = CKContainer.default()
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                summary = "iCloud available — SwiftData records can sync to the private CloudKit database."
            case .noAccount:
                summary = "No iCloud account on this device. Sign in to Settings → Apple ID to enable backup."
            case .restricted:
                summary = "iCloud is restricted (parental controls or device policy)."
            case .couldNotDetermine:
                summary = "Could not determine iCloud status yet."
            case .temporarilyUnavailable:
                summary = "iCloud temporarily unavailable — try again later."
            @unknown default:
                summary = "Unknown iCloud account status."
            }
        } catch {
            summary = error.localizedDescription
        }
    }
}
