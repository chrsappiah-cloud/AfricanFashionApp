//
//  DiscussionViewModel.swift
//  AfricanFashionApp
//

import Foundation
import Combine

@MainActor
final class DiscussionViewModel: ObservableObject {
    @Published var channels: [DiscussionChannel] = []
    @Published var selectedChannelID: String?
    @Published var threads: [DiscussionThread] = []
    @Published var draftTitle = ""
    @Published var draftMessage = ""
    @Published var pipelineStatus: APIPipelineStatus?
    @Published var isLoading = true
    @Published var isCreating = false
    @Published var errorMessage: String?

    private let apiClient: DiscussionAPIClient
    private var pollingTask: Task<Void, Never>?

    init(apiClient: DiscussionAPIClient = DiscussionAPIClient()) {
        self.apiClient = apiClient
    }

    deinit {
        pollingTask?.cancel()
    }

    func start() async {
        await reload()
        startRealtimePolling()
    }

    func stop() {
        pollingTask?.cancel()
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        do {
            async let feed = apiClient.fetchFeed(channelID: selectedChannelID)
            async let pipeline = apiClient.fetchPipelineStatus()
            let (resolvedFeed, resolvedPipeline) = try await (feed, pipeline)
            channels = resolvedFeed.channels
            threads = resolvedFeed.threads
            pipelineStatus = resolvedPipeline
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func selectChannel(_ id: String?) async {
        selectedChannelID = id
        await reload()
    }

    func createThread() async {
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !message.isEmpty else { return }
        let channel = selectedChannelID ?? channels.first?.id ?? "style-lab"

        isCreating = true
        errorMessage = nil
        defer { isCreating = false }
        do {
            _ = try await apiClient.createThread(channelID: channel, title: title, message: message)
            draftTitle = ""
            draftMessage = ""
            await reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startRealtimePolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(8))
                guard !Task.isCancelled else { return }
                await reload()
            }
        }
    }
}
