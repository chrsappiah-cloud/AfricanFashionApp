//
//  AuthView.swift
//  AfricanFashionApp
//

import SwiftData
import SwiftUI

struct AuthView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Sign in")
                    .font(DesignSystem.Typography.title())
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                GlassCard {
                    VStack(spacing: 14) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                    }
                }

                PrimaryButton(title: "Continue") {
                    Task { await submitSignIn() }
                }
                .disabled(isSubmitting)

                if let errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(DesignSystem.Typography.caption())
                        .foregroundStyle(.orange)
                }

                Button("Use demo sign-in") {
                    applyDemoSession()
                }
                .font(DesignSystem.Typography.caption())
                .foregroundStyle(DesignSystem.Colors.accentSecondary)
                .disabled(isSubmitting)

                Text("Biometric and passkey flows plug in here alongside your auth service.")
                    .font(DesignSystem.Typography.caption())
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .padding(20)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
    }

    private func submitSignIn() async {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !password.isEmpty else {
            errorMessage = "Enter email and password."
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let session = try await AuthAPIClient.signIn(email: trimmed, password: password)
            await MainActor.run {
                errorMessage = nil
                appState.applySignIn(
                    email: session.email,
                    displayName: session.displayName,
                    accessToken: session.accessToken
                )
                try? CloudUserProfileRepository.upsertPrimary(appState: appState, into: modelContext)
            }
        } catch {
            await MainActor.run {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    private func applyDemoSession() {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let localPart = trimmed.split(separator: "@").first.map(String.init) ?? "Guest"
        let token = "demo.\(UUID().uuidString)"
        appState.applySignIn(
            email: trimmed.isEmpty ? "guest@local.test" : trimmed,
            displayName: localPart,
            accessToken: token
        )
        try? CloudUserProfileRepository.upsertPrimary(appState: appState, into: modelContext)
    }
}

#Preview {
    NavigationStack {
        AuthView()
            .environmentObject(AppState())
    }
    .modelContainer(PreviewModelContainer.cloudSchema)
}
