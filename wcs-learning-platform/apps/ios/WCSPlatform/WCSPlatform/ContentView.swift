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
                VStack(spacing: 16) {
                    Text("Could not load")
                        .font(.headline)
                    Text(message)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Text(WCSPlatformURL.default.absoluteString)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                    Button("Try again") {
                        loadError = nil
                        reloadToken += 1
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(24)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding()
            } else if isLoading {
                ProgressView("Loading…")
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        loadError = nil
                        reloadToken += 1
                    } label: {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding(.top, 12)
                    .padding(.trailing, 12)
                    .accessibilityLabel("Reload web content")
                }
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}
