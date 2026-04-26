import SwiftUI

struct ContentView: View {
    @State private var reloadToken = 0
    @State private var isLoading = true
    @State private var loadError: String?

    var body: some View {
        ZStack {
            WebPlatformRootView(
                reloadToken: $reloadToken,
                isLoading: $isLoading,
                loadError: $loadError
            )
            .ignoresSafeArea()

            if let message = loadError {
                errorOverlay(message: message)
            } else if isLoading {
                loadingOverlay
            }

            reloadControl
        }
        .preferredColorScheme(.dark)
        .tint(Color(uiColor: WCSWebChrome.accent))
    }

    private var loadingOverlay: some View {
        ProgressView("Loading…")
            .padding(22)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityElement(children: .combine)
    }

    private func errorOverlay(message: String) -> some View {
        VStack(spacing: 16) {
            Text("Could not load")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text(WCSPlatformURL.default.absoluteString)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
            if WCSPlatformURL.isLocalDevDefault {
                Text("Using local dev URL. Set WCSPlatformBaseURL in Info.plist for production.")
                    .font(.caption2)
                    .foregroundStyle(.orange.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            Button("Try again") {
                loadError = nil
                reloadToken += 1
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(20)
        .accessibilityElement(children: .contain)
    }

    private var reloadControl: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    loadError = nil
                    reloadToken += 1
                } label: {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                        .padding(11)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(.top, 6)
                .padding(.trailing, 10)
                .accessibilityLabel("Reload web content")
                .accessibilityHint("Loads the platform URL again from settings.")
            }
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
