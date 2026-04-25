//
//  DiscussionView.swift
//  AfricanFashionApp
//

import SwiftUI

struct DiscussionView: View {
    @StateObject private var viewModel = DiscussionViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.threads.isEmpty {
                ProgressView("Loading discussions...")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        pipelineCard
                        channelStrip
                        composer
                        threadList
                    }
                    .padding(16)
                }
            }
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Discussion")
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.start() }
        .onDisappear { viewModel.stop() }
        .refreshable { await viewModel.reload() }
    }

    private var pipelineCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Realtime pipeline status")
                    .font(DesignSystem.Typography.headline())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                if let status = viewModel.pipelineStatus {
                    Text("API: \(statusWord(status.api)) • Middleware: \(statusWord(status.middleware)) • Realtime: \(statusWord(status.realtime)) • DB: \(statusWord(status.database))")
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    Text(status.message)
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                } else {
                    Text("Checking API, middleware, realtime bus, and database...")
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var channelStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                channelButton(title: "All", id: nil)
                ForEach(viewModel.channels) { channel in
                    channelButton(title: channel.title, id: channel.id)
                }
            }
        }
    }

    private var composer: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Start a new thread")
                    .font(DesignSystem.Typography.headline())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                TextField("Thread title", text: $viewModel.draftTitle)
                    .textFieldStyle(.roundedBorder)
                TextEditor(text: $viewModel.draftMessage)
                    .frame(minHeight: 90)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button {
                    Task { await viewModel.createThread() }
                } label: {
                    if viewModel.isCreating {
                        ProgressView()
                    } else {
                        Label("Post to Discussion", systemImage: "paperplane.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignSystem.Colors.accent)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var threadList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active threads")
                .font(DesignSystem.Typography.title())
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            if viewModel.threads.isEmpty {
                ContentUnavailableView("No threads yet", systemImage: "bubble.left.and.bubble.right", description: Text("Start the first conversation for this channel."))
            } else {
                ForEach(viewModel.threads) { thread in
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(thread.title)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                Spacer()
                                if thread.isPinned {
                                    Label("Pinned", systemImage: "pin.fill")
                                        .font(DesignSystem.Typography.caption())
                                        .foregroundStyle(DesignSystem.Colors.accentSecondary)
                                }
                            }
                            Text(thread.message)
                                .font(DesignSystem.Typography.body())
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                            HStack {
                                Text("\(thread.authorName) • \(thread.authorRole)")
                                Spacer()
                                Label("\(thread.replyCount)", systemImage: "bubble.left")
                                Label("\(thread.likeCount)", systemImage: "hand.thumbsup")
                            }
                            .font(DesignSystem.Typography.caption())
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private func channelButton(title: String, id: String?) -> some View {
        let selected = viewModel.selectedChannelID == id
        return Button(title) {
            Task { await viewModel.selectChannel(id) }
        }
        .font(DesignSystem.Typography.caption())
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(selected ? DesignSystem.Colors.accent.opacity(0.3) : DesignSystem.Colors.surface.opacity(0.8), in: Capsule())
        .overlay {
            Capsule().stroke(DesignSystem.Colors.stroke, lineWidth: 1)
        }
    }

    private func statusWord(_ value: Bool) -> String {
        value ? "online" : "offline"
    }
}

#Preview {
    NavigationStack {
        DiscussionView()
    }
}
