//
//  OnboardingView.swift
//  AfricanFashionApp
//

import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @State private var region = "West Africa"
    @State private var styleNote = "Sculptural silhouettes"

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()
            LinearGradient(
                colors: [
                    DesignSystem.Colors.accent.opacity(0.35),
                    DesignSystem.Colors.background,
                    DesignSystem.Colors.accentSecondary.opacity(0.22),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("African Fashion")
                        .font(DesignSystem.Typography.heroTitle())
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("A premium marketplace for fabrics, tailoring, and accessories—crafted with hyperreal presentation and a futuristic editorial lens.")
                        .font(DesignSystem.Typography.body())
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Region focus")
                                .font(DesignSystem.Typography.headline())
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            Picker("Region", selection: $region) {
                                Text("West Africa").tag("West Africa")
                                Text("East Africa").tag("East Africa")
                                Text("Southern Africa").tag("Southern Africa")
                                Text("Diaspora").tag("Diaspora")
                            }
                            .pickerStyle(.menu)
                            .tint(DesignSystem.Colors.accent)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Style preferences")
                                .font(DesignSystem.Typography.headline())
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            TextField("Describe your look", text: $styleNote)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    PrimaryButton(title: "Enter the atelier") {
                        appState.markOnboardingComplete(regionFocus: region, styleNote: styleNote)
                        try? CloudAdministrationRepository.ensurePrimary(into: modelContext)
                        try? CloudUserProfileRepository.upsertPrimary(appState: appState, into: modelContext)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 36)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
        .modelContainer(PreviewModelContainer.cloudSchema)
}
