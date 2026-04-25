//
//  StorageArchitectureStatusViewModel.swift
//  AfricanFashionApp
//

import Foundation
import Combine

@MainActor
final class StorageArchitectureStatusViewModel: ObservableObject {
    @Published private(set) var status: StorageBackendsStatusPayload?
    @Published private(set) var blueprint: DatabaseBlueprintPayload?
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: String?

    private let apiClient: StorageArchitectureAPIClient

    init(apiClient: StorageArchitectureAPIClient = StorageArchitectureAPIClient()) {
        self.apiClient = apiClient
    }

    func refresh() async {
        isLoading = true
        lastError = nil
        do {
            async let statusTask = apiClient.fetchStorageBackendsStatus()
            async let blueprintTask = apiClient.fetchDatabaseBlueprint()
            status = try await statusTask
            blueprint = try await blueprintTask
        } catch {
            lastError = error.localizedDescription
        }
        isLoading = false
    }
}
