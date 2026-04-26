//
//  ProfileView.swift
//  AfricanFashionApp
//

import SwiftData
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appRouter: AppRouter
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @StateObject private var cloudDiagnostics = CloudKitAccountDiagnostics()
    @StateObject private var storageStatusViewModel = StorageArchitectureStatusViewModel()

    @Query(sort: \CloudProductMediaAsset.updatedAt, order: .reverse)
    private var cloudMediaAssets: [CloudProductMediaAsset]

    private var outboundLinks: BrandOutboundLinks { BrandOutboundLinks.current }

    init() {
        _cloudMediaAssets = Query(sort: \CloudProductMediaAsset.updatedAt, order: .reverse)
    }

    var body: some View {
        NavigationStack(path: $appRouter.profilePath) {
            List {
                Section("iCloud backup (SwiftData + CloudKit)") {
                    Text(cloudDiagnostics.summary)
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Button("Refresh iCloud status") {
                        Task { await cloudDiagnostics.refresh() }
                    }
                    .disabled(cloudDiagnostics.isChecking)

                    Button("Write test backup row") {
                        let stamp = ISO8601DateFormatter().string(from: Date())
                        let data = Data("backup-ping-\(stamp)".utf8)
                        try? CloudBackupRepository.upsert(slug: CloudBackupSlugs.healthcheck, payload: data, into: modelContext)
                    }

                    Button("Push profile + admin snapshot now") {
                        mirrorUserAndAdministrationToCloud()
                    }

                    Text(
                        "User profile, administration JSON, cart snapshot, and media metrics sync to your private CloudKit database. "
                            + "Large image, audio, and video files should stay on CDN or object storage; this app stores URLs plus technical metrics (dimensions, duration, codecs, checksum prefix) for realtime catalog and upload tracking."
                    )
                    .font(DesignSystem.Typography.caption())
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Section("Backend storage routing") {
                    if let status = storageStatusViewModel.status {
                        LabeledContent("Write provider") {
                            Text(status.activeWriteProvider)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                        LabeledContent("Read provider") {
                            Text(status.activeReadProvider)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                        LabeledContent("Failover") {
                            Text(status.failoverEnabled ? "Enabled" : "Disabled")
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }

                        ForEach(status.providers) { provider in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(provider.provider.capitalized) · \(provider.status.capitalized)")
                                    .font(DesignSystem.Typography.headline())
                                Text(provider.capabilities.joined(separator: " • "))
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                                if let cloudKit = provider.cloudKit {
                                    Text("CloudKit: \(cloudKit.containerID) · \(cloudKit.replicationMode)")
                                        .font(DesignSystem.Typography.caption())
                                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } else if storageStatusViewModel.isLoading {
                        ProgressView("Loading storage backend status...")
                    } else {
                        Text("Storage backend status unavailable. Tap refresh to query backend.")
                            .font(DesignSystem.Typography.caption())
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }

                    if let blueprint = storageStatusViewModel.blueprint {
                        Text("Schema: \(blueprint.relationalCore.engine) · \(blueprint.relationalCore.tables.count) tables")
                            .font(DesignSystem.Typography.caption())
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }

                    if let error = storageStatusViewModel.lastError {
                        Text(error)
                            .font(DesignSystem.Typography.caption())
                            .foregroundStyle(.red)
                    }

                    Button("Refresh backend storage status") {
                        Task { await storageStatusViewModel.refresh() }
                    }
                    .disabled(storageStatusViewModel.isLoading)
                }

                Section("Product media metrics (\(cloudMediaAssets.count) rows)") {
                    if cloudMediaAssets.isEmpty {
                        Text("No media metric rows yet. Add catalog or upload metadata from your pipeline.")
                            .font(DesignSystem.Typography.caption())
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    } else {
                        ForEach(cloudMediaAssets.prefix(8), id: \.assetID) { asset in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(asset.mediaKind.uppercased()) · \(asset.role)")
                                    .font(DesignSystem.Typography.headline())
                                Text(asset.remoteURLString)
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                                    .lineLimit(2)
                                Text(mediaMetricsLine(for: asset))
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                            }
                        }
                    }

                    Button("Insert sample image + video metric rows") {
                        insertSampleMediaMetrics()
                    }
                }

                Section("Account") {
                    LabeledContent("Status") {
                        Text(appState.isAuthenticated ? "Signed in" : "Guest")
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }

                    NavigationLink {
                        AuthView()
                    } label: {
                        Text(appState.isAuthenticated ? "Manage sign-in" : "Sign in")
                    }
                }

                Section("Commerce") {
                    Button("Order history") {
                        appRouter.openOrders()
                    }
                    Button("Upload studio") {
                        appRouter.openUploadStudio()
                    }
                    NavigationLink {
                        MembershipPaymentsHubView()
                    } label: {
                        Text("Membership & card payouts")
                    }
                }

                Section("Social & community") {
                    if outboundLinks.socialPairs.isEmpty {
                        Text(
                            "Set SOCIAL_INSTAGRAM_URL, SOCIAL_TIKTOK_URL, SOCIAL_FACEBOOK_URL, SOCIAL_X_URL, SOCIAL_YOUTUBE_CHANNEL_URL, or SOCIAL_LINKEDIN_URL in your scheme to surface deep links for guests, enrolled learners, and admins."
                        )
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    } else {
                        ForEach(Array(outboundLinks.socialPairs.enumerated()), id: \.offset) { _, pair in
                            Link(pair.label, destination: pair.url)
                        }
                    }
                }

                Section("Support") {
                    Link("Care & authenticity", destination: URL(string: "https://example.com/care")!)
                    Link("Licensing & provenance", destination: URL(string: "https://example.com/licensing")!)
                    Text(copyrightLine)
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(DesignSystem.Colors.background)
            .navigationTitle("Profile")
            .task {
                await cloudDiagnostics.refresh()
                await storageStatusViewModel.refresh()
            }
            .navigationDestination(for: AppRouter.Destination.self) { destination in
                switch destination {
                case .orders:
                    OrdersView()
                case .uploadStudio:
                    UploadStudioView()
                case .checkout:
                    CheckoutView()
                case .product(let id):
                    ProductDetailView(productID: id)
                }
            }
        }
    }

    private func mirrorUserAndAdministrationToCloud() {
        try? CloudAdministrationRepository.ensurePrimary(into: modelContext)
        try? CloudUserProfileRepository.upsertPrimary(appState: appState, into: modelContext)
    }

    private func insertSampleMediaMetrics() {
        let productID = UUID()
        let imageDraft = CloudProductMediaDraft(
            assetID: UUID(),
            productID: productID,
            mediaKind: "image",
            role: "hero",
            remoteURLString: "https://cdn.example.com/products/\(productID.uuidString)/hero.jpg",
            byteLength: 312_000,
            pixelWidth: 2048,
            pixelHeight: 2730,
            durationSeconds: nil,
            frameRate: nil,
            mimeType: "image/jpeg",
            codecIdentifier: "jpeg",
            checksumPrefixHex: String(repeating: "0", count: 32),
            etagOrRevision: "\"w1\"",
            processingState: "ready",
            sortIndex: 0
        )
        let videoDraft = CloudProductMediaDraft(
            assetID: UUID(),
            productID: productID,
            mediaKind: "video",
            role: "lookbook",
            remoteURLString: "https://cdn.example.com/products/\(productID.uuidString)/lookbook_1080p.mp4",
            byteLength: 12_400_000,
            pixelWidth: 1920,
            pixelHeight: 1080,
            durationSeconds: 42.5,
            frameRate: 30,
            mimeType: "video/mp4",
            codecIdentifier: "h264",
            checksumPrefixHex: String(repeating: "f", count: 32),
            etagOrRevision: "\"w2\"",
            processingState: "ready",
            sortIndex: 1
        )
        let audioDraft = CloudProductMediaDraft(
            assetID: UUID(),
            productID: productID,
            mediaKind: "audio",
            role: "voiceover",
            remoteURLString: "https://cdn.example.com/products/\(productID.uuidString)/narration.m4a",
            byteLength: 890_000,
            pixelWidth: nil,
            pixelHeight: nil,
            durationSeconds: 118,
            frameRate: nil,
            mimeType: "audio/mp4",
            codecIdentifier: "aac",
            checksumPrefixHex: String(repeating: "c", count: 32),
            etagOrRevision: "\"w3\"",
            processingState: "ready",
            sortIndex: 2
        )
        try? CloudProductMediaRepository.upsert(imageDraft, into: modelContext)
        try? CloudProductMediaRepository.upsert(videoDraft, into: modelContext)
        try? CloudProductMediaRepository.upsert(audioDraft, into: modelContext)
    }

    private func mediaMetricsLine(for asset: CloudProductMediaAsset) -> String {
        var parts: [String] = []
        if let w = asset.pixelWidth, let h = asset.pixelHeight {
            parts.append("\(w)×\(h) px")
        }
        if let d = asset.durationSeconds {
            parts.append(String(format: "%.1f s", d))
        }
        if let fps = asset.frameRate {
            parts.append(String(format: "%.0f fps", fps))
        }
        if let bytes = asset.byteLength {
            parts.append(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))
        }
        if let mime = asset.mimeType {
            parts.append(mime)
        }
        if let codec = asset.codecIdentifier {
            parts.append(codec)
        }
        return parts.joined(separator: " · ")
    }

    private var copyrightLine: String {
        let year = Calendar.current.component(.year, from: Date())
        return "© \(year) World Class Scholars. All rights reserved."
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppRouter())
        .environmentObject(AppState())
        .modelContainer(PreviewModelContainer.cloudSchema)
}
