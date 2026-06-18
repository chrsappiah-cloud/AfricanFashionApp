//
//  DesignStudioView.swift
//  AfricanFashionApp
//

import SwiftData
import SwiftUI

struct DesignStudioView: View {
    @State private var selectedSection: StudioSection = .launchDefault

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Studio section", selection: $selectedSection) {
                    ForEach(StudioSection.allCases) { section in
                        Label(section.title, systemImage: section.systemImage)
                            .tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("studio-section-picker")
                .padding([.horizontal, .top])

                Group {
                    switch selectedSection {
                    case .dashboard:
                        DesignStudioDashboardView()
                    case .clients:
                        ClientProfilesStudioView()
                    case .generate:
                        DesignGeneratorView()
                    case .trends:
                        TrendLabView()
                    case .board:
                        CollectionBoardStudioView()
                    }
                }
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Design Studio")
            .accessibilityIdentifier("design-studio-root")
        }
    }
}

private enum StudioSection: String, CaseIterable, Identifiable {
    case dashboard
    case clients
    case generate
    case trends
    case board

    var id: String { rawValue }

    static var launchDefault: StudioSection {
        let arguments = ProcessInfo.processInfo.arguments
        guard
            let flagIndex = arguments.firstIndex(of: "-uiTestingStudioSection"),
            arguments.indices.contains(arguments.index(after: flagIndex))
        else {
            return .dashboard
        }

        let valueIndex = arguments.index(after: flagIndex)
        return StudioSection(rawValue: arguments[valueIndex]) ?? .dashboard
    }

    var title: String {
        switch self {
        case .dashboard: "Studio"
        case .clients: "Clients"
        case .generate: "Generate"
        case .trends: "Trends"
        case .board: "Board"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .clients: "person.2"
        case .generate: "wand.and.stars"
        case .trends: "chart.line.uptrend.xyaxis"
        case .board: "rectangle.stack"
        }
    }
}

private struct DesignStudioDashboardView: View {
    @StateObject private var viewModel = DesignStudioDashboardViewModel()
    @Query private var clientRecords: [StudioClientRecord]
    @Query private var lookRecords: [StudioGeneratedLookRecord]
    @Query private var trendRecords: [StudioTrendSignalRecord]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("AI-assisted fashion workflow", systemImage: "sparkles")
                            .font(DesignSystem.Typography.headline())
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("Create measurement-aware garment concepts, compare trend signals, and shape collection boards for African luxury fashion.")
                            .font(DesignSystem.Typography.body())
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        HStack(spacing: 10) {
                            metric(title: "Clients", value: "\(max(clientRecords.count, 1))")
                            metric(title: "Saved looks", value: "\(max(lookRecords.count, viewModel.activeCollection.looks.count))")
                            metric(title: "Signals", value: "\(max(trendRecords.count, 4))")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text("Active collection")
                    .font(DesignSystem.Typography.title())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                CollectionSummaryCard(collection: viewModel.activeCollection)

                Text("Sample client")
                    .font(DesignSystem.Typography.title())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                ClientProfileCard(profile: viewModel.sampleClient)
            }
            .padding()
        }
        .accessibilityIdentifier("studio-board-screen")
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(DesignSystem.Typography.title())
                .foregroundStyle(DesignSystem.Colors.accent)
            Text(title)
                .font(DesignSystem.Typography.caption())
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(DesignSystem.Colors.surface.opacity(0.7), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct ClientProfilesStudioView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudioClientRecord.updatedAt, order: .reverse) private var clientRecords: [StudioClientRecord]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(displayProfiles) { profile in
                    ClientProfileCard(profile: profile)
                }
            }
            .padding()
        }
        .task {
            seedClientsIfNeeded()
        }
    }

    private var displayProfiles: [DesignerClientProfile] {
        if clientRecords.isEmpty {
            return [.sample, Self.secondarySample]
        }
        return clientRecords.map(\.profile)
    }

    private func seedClientsIfNeeded() {
        guard clientRecords.isEmpty else { return }
        modelContext.insert(StudioClientRecord(profile: .sample))
        modelContext.insert(StudioClientRecord(profile: Self.secondarySample))
        try? modelContext.save()
    }

    private static let secondarySample = DesignerClientProfile(
        id: UUID(uuidString: "00000000-0000-4000-8000-000000000102")!,
        name: "Nia Okafor",
        stylePreferences: ["minimal resortwear", "relaxed tailoring", "natural fibers"],
        favoriteColors: ["ivory", "terracotta", "indigo"],
        dislikedElements: ["synthetic sheen"],
        bodyMeasurements: BodyMeasurements(heightCm: 165, bustCm: 84, waistCm: 68, hipCm: 92, inseamCm: 74, shoulderCm: 38),
        occasions: ["destination wedding", "brand launch"],
        notes: "Wants breathable fabrics and versatile styling."
    )
}

private struct DesignGeneratorView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DesignGeneratorViewModel()
    @Query(sort: \StudioGeneratedLookRecord.createdAt, order: .reverse) private var savedLookRecords: [StudioGeneratedLookRecord]

    var body: some View {
        Form {
            Section("Garment brief") {
                TextField("Title", text: $viewModel.title)
                TextField("Category", text: $viewModel.category)
                TextField("Season", text: $viewModel.season)
                TextField("Silhouette", text: $viewModel.silhouette)
                TextField("Fabrics", text: $viewModel.fabricInput)
                TextField("Colors", text: $viewModel.colorInput)
            }

            Section("Client fit") {
                MeasurementField(label: "Height", value: $viewModel.heightCm)
                MeasurementField(label: "Bust", value: $viewModel.bustCm)
                MeasurementField(label: "Waist", value: $viewModel.waistCm)
                MeasurementField(label: "Hip", value: $viewModel.hipCm)
                MeasurementField(label: "Inseam", value: $viewModel.inseamCm)
                MeasurementField(label: "Shoulder", value: $viewModel.shoulderCm)
            }

            Section("Style direction") {
                TextField("Aesthetic", text: $viewModel.aesthetic)
                TextField("Occasion", text: $viewModel.occasion)
                TextField("Design notes", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                Button {
                    viewModel.composePrompt()
                } label: {
                    Label("Generate Prompt", systemImage: "text.quote")
                }
                .accessibilityIdentifier("studio-generate-prompt-button")

                Button {
                    Task {
                        await viewModel.generateDesign()
                        saveGeneratedLookIfNeeded()
                    }
                } label: {
                    Label(viewModel.isGenerating ? "Generating" : "Generate Design", systemImage: "wand.and.stars")
                }
                .disabled(viewModel.isGenerating)
            }

            if !viewModel.generatedPrompt.isEmpty {
                Section("Generated prompt") {
                    Text(viewModel.generatedPrompt)
                        .font(DesignSystem.Typography.body())
                        .accessibilityIdentifier("studio-generated-prompt-text")
                }
            }

            if let look = viewModel.generatedLook {
                Section("Preview concept") {
                    GeneratedLookCard(look: look)
                }
            }

            if !savedLookRecords.isEmpty {
                Section("Saved concepts") {
                    ForEach(savedLookRecords.prefix(3)) { record in
                        GeneratedLookCard(look: record.look)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.background)
        .accessibilityIdentifier("studio-generator-screen")
    }

    private func saveGeneratedLookIfNeeded() {
        guard let look = viewModel.generatedLook,
              !savedLookRecords.contains(where: { $0.id == look.id })
        else { return }
        modelContext.insert(StudioGeneratedLookRecord(look: look))
        try? modelContext.save()
    }
}

private struct TrendLabView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = TrendLabViewModel()
    @Query(sort: \StudioTrendSignalRecord.capturedAt, order: .reverse) private var savedTrendRecords: [StudioTrendSignalRecord]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Trend forecast inputs")
                            .font(DesignSystem.Typography.headline())
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        TextField("Market", text: $viewModel.market)
                        TextField("Season", text: $viewModel.season)
                        TextField("Audience", text: $viewModel.audience)
                        TextField("Category", text: $viewModel.category)
                        Button {
                            Task {
                                await viewModel.load()
                                saveTrendSignals()
                            }
                        } label: {
                            Label(viewModel.isLoading ? "Loading" : "Refresh Trend Signals", systemImage: "chart.line.uptrend.xyaxis")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(DesignSystem.Colors.accent)
                        .disabled(viewModel.isLoading)
                        .accessibilityIdentifier("studio-refresh-trends-button")
                    }
                }

                if !viewModel.trendPrompt.isEmpty {
                    promptCard(title: "Forecast prompt", text: viewModel.trendPrompt)
                }

                ForEach(viewModel.trends) { trend in
                    TrendSignalCard(signal: trend)
                }

                if !savedTrendRecords.isEmpty {
                    Text("Saved trend history")
                        .font(DesignSystem.Typography.title())
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    ForEach(savedTrendRecords.prefix(4)) { record in
                        TrendSignalCard(signal: record.signal)
                    }
                }
            }
            .padding()
        }
        .task {
            await viewModel.load()
            saveTrendSignals()
        }
        .accessibilityIdentifier("studio-trends-screen")
    }

    private func saveTrendSignals() {
        for signal in viewModel.trends where !savedTrendRecords.contains(where: { $0.id == signal.id }) {
            modelContext.insert(StudioTrendSignalRecord(signal: signal, market: viewModel.market, season: viewModel.season))
        }
        try? modelContext.save()
    }

    private func promptCard(title: String, text: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(DesignSystem.Typography.headline())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(text)
                    .font(DesignSystem.Typography.caption())
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct CollectionBoardStudioView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DesignStudioDashboardViewModel()
    @Query(sort: \StudioGeneratedLookRecord.createdAt, order: .reverse) private var savedLookRecords: [StudioGeneratedLookRecord]
    @Query(sort: \StudioTrendSignalRecord.capturedAt, order: .reverse) private var savedTrendRecords: [StudioTrendSignalRecord]
    @State private var selectedTechPack: TechPackDocument?

    private let techPackService: TechPackGenerating = FashionTechPackService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CollectionSummaryCard(collection: viewModel.activeCollection)
                ForEach(collectionLooks) { look in
                    VStack(alignment: .leading, spacing: 10) {
                        GeneratedLookCard(look: look)
                        HStack(spacing: 10) {
                            Button {
                                createRevision(from: look)
                            } label: {
                                Label("New Version", systemImage: "arrow.triangle.2.circlepath")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(DesignSystem.Colors.accentSecondary)
                            .accessibilityIdentifier("studio-new-version-button")

                            Button {
                                selectedTechPack = techPackService.makeTechPack(
                                    look: look,
                                    measurements: BodyMeasurements.sample,
                                    trends: savedTrendRecords.prefix(4).map(\.signal)
                                )
                            } label: {
                                Label("Tech Pack", systemImage: "doc.richtext")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("studio-tech-pack-button")
                            .tint(DesignSystem.Colors.accent)
                        }
                    }
                }

                if let selectedTechPack {
                    TechPackPreviewCard(document: selectedTechPack)
                }
            }
            .padding()
        }
    }

    private var collectionLooks: [GeneratedLook] {
        let savedLooks = savedLookRecords.map(\.look)
        return savedLooks.isEmpty ? viewModel.activeCollection.looks : savedLooks
    }

    private func createRevision(from look: GeneratedLook) {
        let revision = GeneratedLook(
            id: UUID(),
            title: look.title,
            prompt: look.prompt,
            imageURL: look.imageURL,
            notes: "\(look.notes)\nRevision note: refine fit, styling, or material direction before regenerating.",
            createdAt: .now,
            versionNumber: look.versionNumber + 1,
            parentLookID: look.parentLookID ?? look.id
        )
        modelContext.insert(StudioGeneratedLookRecord(look: revision))
        try? modelContext.save()
    }
}

private struct MeasurementField: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField(label, value: $value, format: .number.precision(.fractionLength(0)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            Text("cm")
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }
}

private struct ClientProfileCard: View {
    let profile: DesignerClientProfile

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(profile.name, systemImage: "person.crop.circle")
                        .font(DesignSystem.Typography.headline())
                    Spacer()
                    Text(profile.occasions.first ?? "Custom")
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(DesignSystem.Colors.accent)
                }
                Text(profile.stylePreferences.joined(separator: " · "))
                    .font(DesignSystem.Typography.body())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("Measurements: \(Int(profile.bodyMeasurements.heightCm)) cm height · \(Int(profile.bodyMeasurements.bustCm))/\(Int(profile.bodyMeasurements.waistCm))/\(Int(profile.bodyMeasurements.hipCm)) bust/waist/hip")
                    .font(DesignSystem.Typography.caption())
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Text("Palette: \(profile.favoriteColors.joined(separator: ", "))")
                    .font(DesignSystem.Typography.caption())
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct CollectionSummaryCard: View {
    let collection: CollectionPlan

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Label(collection.title, systemImage: "rectangle.stack")
                    .font(DesignSystem.Typography.headline())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text("\(collection.market) · \(collection.season) · \(collection.looks.count) saved looks")
                    .font(DesignSystem.Typography.body())
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Text("Collection board combines AI-generated garment prompts, trend evidence, notes, and market positioning for export-ready design review.")
                    .font(DesignSystem.Typography.caption())
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct TrendSignalCard: View {
    let signal: TrendSignal

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(signal.category)
                        .font(DesignSystem.Typography.headline())
                    Spacer()
                    Text("\(Int(signal.confidence * 100))%")
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(DesignSystem.Colors.accent)
                }
                Text(signal.summary)
                    .font(DesignSystem.Typography.body())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(signal.designDirection)
                    .font(DesignSystem.Typography.caption())
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Text(signal.keywords.joined(separator: " • "))
                    .font(DesignSystem.Typography.caption())
                    .foregroundStyle(DesignSystem.Colors.accentSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct GeneratedLookCard: View {
    let look: GeneratedLook

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(look.title)
                        .font(DesignSystem.Typography.headline())
                    Spacer()
                    Text("v\(look.versionNumber)")
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(DesignSystem.Colors.accent)
                    Text(look.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                AsyncImage(url: look.imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        imageFallback
                    case .empty:
                        imageFallback
                    @unknown default:
                        imageFallback
                    }
                }
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(DesignSystem.Colors.stroke, lineWidth: 1)
                }

                Text(look.notes)
                    .font(DesignSystem.Typography.body())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Text(look.prompt)
                    .font(DesignSystem.Typography.caption())
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var imageFallback: some View {
        ZStack {
            LinearGradient(
                colors: [DesignSystem.Colors.accent.opacity(0.5), DesignSystem.Colors.accentSecondary.opacity(0.45)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "tshirt")
                .font(.system(size: 70, weight: .thin))
                .foregroundStyle(.white.opacity(0.65))
        }
    }
}

private struct TechPackPreviewCard: View {
    let document: TechPackDocument

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label(document.title, systemImage: "doc.richtext")
                    .font(DesignSystem.Typography.headline())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("PDF-ready sections generated \(document.generatedAt.formatted(date: .abbreviated, time: .shortened)).")
                    .font(DesignSystem.Typography.caption())
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                ForEach(document.sections) { section in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(section.title)
                            .font(DesignSystem.Typography.headline())
                            .foregroundStyle(DesignSystem.Colors.accent)
                        Text(section.body)
                            .font(DesignSystem.Typography.caption())
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    DesignStudioView()
}
