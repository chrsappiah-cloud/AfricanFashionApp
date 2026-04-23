//
//  UploadStudioView.swift
//  AfricanFashionApp
//

import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct UploadStudioView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @State private var pickerItem: PhotosPickerItem?
    @State private var isFileImporterPresented = false
    @State private var remoteURLString = "https://picsum.photos/900/1200"
    @State private var statusMessage = "Import media to attach provenance metadata."
    @State private var isWorking = false
    /// Groups studio uploads until a listing draft exists; replace with server listing id when wired.
    @State private var draftListingID = UUID()
    @State private var stagedUploads: [StagedUploadPreview] = []
    @State private var apiHealth = UploadAPIHealthSnapshot.idle
    @State private var uploadProbePath = BackendAPI.defaultUploadProbePath
    @State private var uploadProbe = UploadProbeResult.idle

    private let uploadService = UploadService()
    private let httpClient = URLSessionHTTPClient()

    var body: some View {
        Form {
            Section("Local intake") {
                PhotosPicker("Choose from library", selection: $pickerItem, matching: .images)
                    .onChange(of: pickerItem) { _, item in
                        Task { await handlePicker(item) }
                    }

                Button("Choose from Files") {
                    isFileImporterPresented = true
                }
                .disabled(isWorking)

                Button("Simulate file ingest") {
                    Task { await ingestLocalDemo() }
                }
                .disabled(isWorking)
            }

            Section("Remote URL") {
                TextField("https://", text: $remoteURLString)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)

                Button("Fetch metadata & stage") {
                    Task { await ingestRemote() }
                }
                .disabled(isWorking)
            }

            Section("Status") {
                Text(statusMessage)
                    .font(DesignSystem.Typography.caption())
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Section("Upload API health") {
                LabeledContent("Environment") {
                    Text(AppConfiguration.current.environment.rawValue.capitalized)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                LabeledContent("Base URL") {
                    Text(AppConfiguration.current.environment.apiBaseURL.absoluteString)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                LabeledContent("Auth state") {
                    Text(appState.isAuthenticated ? "Signed in (\(tokenLabel))" : "Guest")
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                LabeledContent("Last check") {
                    Text(apiHealth.timestampText)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                LabeledContent("Result") {
                    Text(apiHealth.summary)
                        .foregroundStyle(apiHealth.isHealthy ? .green : .orange)
                        .lineLimit(2)
                }
                if let details = apiHealth.details, !details.isEmpty {
                    Text(details)
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(4)
                }
                Button("Check backend + middleware now") {
                    Task { await runAPIHealthCheck() }
                }
                .disabled(apiHealth.isChecking)
            }

            Section("Upload middleware probe") {
                TextField("/v1/uploads/presign", text: $uploadProbePath)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)

                LabeledContent("Last request") {
                    Text(uploadProbe.timestampText)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                LabeledContent("Status") {
                    Text(uploadProbe.summary)
                        .foregroundStyle(uploadProbe.isSuccess ? .green : .orange)
                }
                if let details = uploadProbe.details {
                    Text(details)
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(5)
                }
                Button("Probe upload endpoint") {
                    Task { await runUploadProbe() }
                }
                .disabled(uploadProbe.isChecking)
            }

            if !stagedUploads.isEmpty {
                Section("Staged uploads (\(stagedUploads.count))") {
                    ForEach(stagedUploads) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 10) {
                                Group {
                                    if let data = item.localData, let image = UIImage(data: data) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        AsyncImage(url: item.remoteURL) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image.resizable().scaledToFill()
                                            default:
                                                Color(white: 0.15)
                                            }
                                        }
                                    }
                                }
                                .frame(width: 72, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(DesignSystem.Colors.stroke, lineWidth: 1)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.filename)
                                        .font(DesignSystem.Typography.headline())
                                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                                    Text(item.sourceLabel)
                                        .font(DesignSystem.Typography.caption())
                                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                                    if let remote = item.remoteURL {
                                        Text(remote.absoluteString)
                                            .font(DesignSystem.Typography.caption())
                                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                                            .lineLimit(2)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.background)
        .navigationTitle("Upload Studio")
        .task {
            await runAPIHealthCheck()
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            Task { await handleFiles(result) }
        }
    }

    private func handlePicker(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                await MainActor.run { statusMessage = "Could not read image data." }
                return
            }
            do {
                try UploadContentValidator.validateListingImageData(data)
            } catch {
                await MainActor.run { statusMessage = error.localizedDescription }
                return
            }
            let dto = try await uploadService.ingest(
                UploadSource(kind: .local(data, filename: "library-import.jpg", mimeType: "image/jpeg"))
            )
            await MainActor.run {
                persistAndTrack(
                    dto: dto,
                    role: "listing.library",
                    sourceLabel: "Photo Library",
                    filename: "library-import.jpg",
                    localData: data
                )
            }
        } catch {
            await MainActor.run {
                statusMessage = error.localizedDescription
            }
        }
    }

    private func handleFiles(_ result: Result<[URL], Error>) async {
        switch result {
        case .success(let urls):
            guard !urls.isEmpty else { return }
            for fileURL in urls {
                do {
                    guard fileURL.startAccessingSecurityScopedResource() else {
                        await MainActor.run { statusMessage = "Unable to access selected file." }
                        continue
                    }
                    defer { fileURL.stopAccessingSecurityScopedResource() }

                    let data = try Data(contentsOf: fileURL)
                    try UploadContentValidator.validateListingImageData(data)
                    let ext = fileURL.pathExtension
                    let mime = UTType(filenameExtension: ext)?.preferredMIMEType ?? "image/jpeg"
                    let dto = try await uploadService.ingest(
                        UploadSource(kind: .local(data, filename: fileURL.lastPathComponent, mimeType: mime))
                    )
                    await MainActor.run {
                        persistAndTrack(
                            dto: dto,
                            role: "listing.files",
                            sourceLabel: "Files App",
                            filename: fileURL.lastPathComponent,
                            localData: data
                        )
                    }
                } catch {
                    await MainActor.run { statusMessage = error.localizedDescription }
                }
            }
        case .failure(let error):
            await MainActor.run { statusMessage = error.localizedDescription }
        }
    }

    private func ingestLocalDemo() async {
        isWorking = true
        defer { isWorking = false }
        do {
            let demo = Data("demo".utf8)
            let dto = try await uploadService.ingest(
                UploadSource(kind: .local(demo, filename: "demo.txt", mimeType: "text/plain"))
            )
            await MainActor.run {
                persistAndTrack(
                    dto: dto,
                    role: "listing.simulated",
                    sourceLabel: "Simulated",
                    filename: "demo.txt",
                    localData: demo
                )
            }
        } catch {
            await MainActor.run { statusMessage = error.localizedDescription }
        }
    }

    private func ingestRemote() async {
        isWorking = true
        defer { isWorking = false }
        guard let url = URL(string: remoteURLString), URLValidator.isAllowedHTTPURL(url) else {
            await MainActor.run { statusMessage = "Enter a valid http(s) URL." }
            return
        }
        do {
            let dto = try await uploadService.ingest(UploadSource(kind: .remote(url)))
            await MainActor.run {
                persistAndTrack(
                    dto: dto,
                    role: "listing.remote_source",
                    sourceLabel: "Remote URL",
                    filename: url.lastPathComponent.isEmpty ? "remote-image" : url.lastPathComponent,
                    localData: nil
                )
            }
        } catch {
            await MainActor.run { statusMessage = error.localizedDescription }
        }
    }

    private func persistAndTrack(
        dto: MediaAssetDTO,
        role: String,
        sourceLabel: String,
        filename: String,
        localData: Data?
    ) {
        try? ProductMediaCloudSync.persistUploadIngest(
            productID: draftListingID,
            role: role,
            dto: dto,
            into: modelContext
        )
        let preview = StagedUploadPreview(
            id: dto.id,
            filename: filename,
            sourceLabel: sourceLabel,
            remoteURL: dto.remoteURL,
            localData: localData
        )
        stagedUploads.insert(preview, at: 0)
        if stagedUploads.count > 25 {
            stagedUploads.removeLast(stagedUploads.count - 25)
        }
        statusMessage = "Staged asset \(dto.id). Upload pipeline + Cloud metrics updated."
    }

    private func runAPIHealthCheck() async {
        await MainActor.run {
            apiHealth = apiHealth.asChecking()
        }

        let baseURL = AppConfiguration.current.environment.apiBaseURL
        let candidates = BackendAPI.healthPaths

        for path in candidates {
            let endpoint = BackendAPI.makeURL(path: path)
            try? BackendAPI.validateTransportSecurity(for: endpoint)
            let token = appState.isAuthenticated ? appState.authAccessToken : nil
            let request = BackendAPI.makeJSONRequest(url: endpoint, method: "GET", bearerToken: token)

            do {
                let (data, response) = try await BackendAPI.executeWithRetry {
                    let (data, response) = try await httpClient.data(for: request)
                    if let http = response as? HTTPURLResponse, BackendAPI.shouldRetry(statusCode: http.statusCode) {
                        throw APIError.status(code: http.statusCode, body: data)
                    }
                    return (data, response)
                }
                guard let http = response as? HTTPURLResponse else {
                    await MainActor.run {
                        apiHealth = UploadAPIHealthSnapshot(
                            isHealthy: false,
                            isChecking: false,
                            summary: "Unexpected response type",
                            details: endpoint.absoluteString,
                            checkedAt: Date()
                        )
                    }
                    return
                }
                if (200 ..< 300).contains(http.statusCode) {
                    let body = String(data: data, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    await MainActor.run {
                        apiHealth = UploadAPIHealthSnapshot(
                            isHealthy: true,
                            isChecking: false,
                            summary: "Healthy (\(http.statusCode))",
                            details: "GET \(endpoint.absoluteString)\(body?.isEmpty == false ? " | \(body!)" : "")",
                            checkedAt: Date()
                        )
                    }
                    return
                }
            } catch {
                continue
            }
        }

        await MainActor.run {
            apiHealth = UploadAPIHealthSnapshot(
                isHealthy: false,
                isChecking: false,
                summary: "Backend unreachable",
                details: "Checked \(candidates.count) endpoints under \(baseURL.absoluteString)",
                checkedAt: Date()
            )
        }
    }

    private func runUploadProbe() async {
        await MainActor.run { uploadProbe = uploadProbe.asChecking() }

        let cleanPath = uploadProbePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanPath.isEmpty else {
            await MainActor.run {
                uploadProbe = UploadProbeResult(
                    isSuccess: false,
                    isChecking: false,
                    summary: "Path required",
                    details: "Enter an endpoint path like /v1/uploads/presign.",
                    checkedAt: Date()
                )
            }
            return
        }

        let endpoint = BackendAPI.makeURL(path: cleanPath)
        do {
            try BackendAPI.validateTransportSecurity(for: endpoint)
        } catch {
            await MainActor.run {
                uploadProbe = UploadProbeResult(
                    isSuccess: false,
                    isChecking: false,
                    summary: "Blocked by transport policy",
                    details: error.localizedDescription,
                    checkedAt: Date()
                )
            }
            return
        }
        let previewName = stagedUploads.first?.filename ?? "probe.jpg"
        let previewBytes = stagedUploads.first?.localData?.count ?? 256_000

        let payload: [String: Any] = [
            "filename": previewName,
            "mimeType": "image/jpeg",
            "byteLength": previewBytes,
            "source": "ios-upload-studio-probe",
            "listingDraftId": draftListingID.uuidString,
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            await MainActor.run {
                uploadProbe = UploadProbeResult(
                    isSuccess: false,
                    isChecking: false,
                    summary: "Payload build failed",
                    details: nil,
                    checkedAt: Date()
                )
            }
            return
        }

        let started = Date()
        let token = appState.isAuthenticated ? appState.authAccessToken : nil
        let request = BackendAPI.makeJSONRequest(
            url: endpoint,
            method: "POST",
            body: body,
            bearerToken: token
        )

        do {
            let (data, response) = try await BackendAPI.executeWithRetry {
                let (data, response) = try await httpClient.data(for: request)
                if let http = response as? HTTPURLResponse, BackendAPI.shouldRetry(statusCode: http.statusCode) {
                    throw APIError.status(code: http.statusCode, body: data)
                }
                return (data, response)
            }
            guard let http = response as? HTTPURLResponse else {
                await MainActor.run {
                    uploadProbe = UploadProbeResult(
                        isSuccess: false,
                        isChecking: false,
                        summary: "Unexpected response type",
                        details: endpoint.absoluteString,
                        checkedAt: Date()
                    )
                }
                return
            }
            let latency = Date().timeIntervalSince(started)
            let bodyText = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            await MainActor.run {
                uploadProbe = UploadProbeResult(
                    isSuccess: (200 ..< 300).contains(http.statusCode),
                    isChecking: false,
                    summary: "HTTP \(http.statusCode) • \(String(format: "%.0f", latency * 1000)) ms",
                    details: "POST \(endpoint.absoluteString)\(bodyText?.isEmpty == false ? " | \(bodyText!)" : "")",
                    checkedAt: Date()
                )
            }
        } catch {
            await MainActor.run {
                uploadProbe = UploadProbeResult(
                    isSuccess: false,
                    isChecking: false,
                    summary: "Request failed",
                    details: "POST \(endpoint.absoluteString) | \(error.localizedDescription)",
                    checkedAt: Date()
                )
            }
        }
    }
}

private extension UploadStudioView {
    var tokenLabel: String {
        guard !appState.authAccessToken.isEmpty else { return "no token" }
        let token = appState.authAccessToken
        let suffix = token.suffix(6)
        return "token•••\(suffix)"
    }
}

private struct StagedUploadPreview: Identifiable, Hashable {
    let id: UUID
    let filename: String
    let sourceLabel: String
    let remoteURL: URL?
    let localData: Data?
}

private struct UploadAPIHealthSnapshot: Equatable {
    var isHealthy: Bool
    var isChecking: Bool
    var summary: String
    var details: String?
    var checkedAt: Date?

    static let idle = UploadAPIHealthSnapshot(
        isHealthy: false,
        isChecking: false,
        summary: "Not checked yet",
        details: nil,
        checkedAt: nil
    )

    var timestampText: String {
        guard let checkedAt else { return "Never" }
        return DateFormatter.localizedString(from: checkedAt, dateStyle: .none, timeStyle: .medium)
    }

    func asChecking() -> UploadAPIHealthSnapshot {
        UploadAPIHealthSnapshot(
            isHealthy: isHealthy,
            isChecking: true,
            summary: "Checking…",
            details: details,
            checkedAt: checkedAt
        )
    }
}

private struct UploadProbeResult: Equatable {
    var isSuccess: Bool
    var isChecking: Bool
    var summary: String
    var details: String?
    var checkedAt: Date?

    static let idle = UploadProbeResult(
        isSuccess: false,
        isChecking: false,
        summary: "Not probed yet",
        details: nil,
        checkedAt: nil
    )

    var timestampText: String {
        guard let checkedAt else { return "Never" }
        return DateFormatter.localizedString(from: checkedAt, dateStyle: .none, timeStyle: .medium)
    }

    func asChecking() -> UploadProbeResult {
        UploadProbeResult(
            isSuccess: isSuccess,
            isChecking: true,
            summary: "Sending probe…",
            details: details,
            checkedAt: checkedAt
        )
    }
}

#Preview {
    NavigationStack {
        UploadStudioView()
    }
    .environmentObject(AppState())
    .modelContainer(PreviewModelContainer.cloudSchema)
}
