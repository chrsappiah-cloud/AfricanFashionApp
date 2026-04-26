import SwiftUI
import WebKit

enum WCSPlatformURL {
    /// UserDefaults override key (debug / internal builds).
    static let userDefaultsOverrideKey = "wcs_platform_base_url"

    /// Resolution order: runtime UserDefaults → `WCSPlatformBaseURL` in Info.plist → local Next.js dev server.
    static var `default`: URL {
        if let s = UserDefaults.standard.string(forKey: userDefaultsOverrideKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !s.isEmpty,
           let u = URL(string: s) {
            return u
        }
        if let raw = Bundle.main.object(forInfoDictionaryKey: "WCSPlatformBaseURL") as? String {
            let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !s.isEmpty, !s.contains("$("), let u = URL(string: s) {
                return u
            }
        }
        return URL(string: "http://127.0.0.1:3000")!
    }

    /// `true` when the shell is pointed at the local Next.js default (not production HTTPS).
    static var isLocalDevDefault: Bool {
        let u = Self.default
        return u.host == "127.0.0.1" || u.host == "localhost"
    }
}

struct WebPlatformRootView: UIViewRepresentable {
    @Binding var reloadToken: Int
    @Binding var isLoading: Bool
    @Binding var loadError: String?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        var lastReloadToken: Int = -1
        var isLoading: Binding<Bool>?
        var loadError: Binding<String?>?
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        if #available(iOS 15.4, *) {
            config.mediaTypesRequiringUserActionForPlayback = []
        }
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.backgroundColor = WCSWebChrome.background
        web.scrollView.contentInsetAdjustmentBehavior = .automatic
        web.allowsBackForwardNavigationGestures = true
        if #available(iOS 15.0, *) {
            web.underPageBackgroundColor = WCSWebChrome.background
        }

        context.coordinator.webView = web
        context.coordinator.lastReloadToken = reloadToken
        context.coordinator.isLoading = _isLoading
        context.coordinator.loadError = _loadError

        let request = URLRequest(url: WCSPlatformURL.default)
        web.load(request)
        return web
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.isLoading = _isLoading
        context.coordinator.loadError = _loadError

        if reloadToken != context.coordinator.lastReloadToken {
            context.coordinator.lastReloadToken = reloadToken
            isLoading = true
            loadError = nil
            webView.load(URLRequest(url: WCSPlatformURL.default))
        }
    }
}

extension WebPlatformRootView.Coordinator {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading?.wrappedValue = true
            self.loadError?.wrappedValue = nil
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading?.wrappedValue = false
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.isLoading?.wrappedValue = false
            self.loadError?.wrappedValue = WCSErrorFormatting.userFacingMessage(for: error)
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.isLoading?.wrappedValue = false
            self.loadError?.wrappedValue = WCSErrorFormatting.userFacingMessage(for: error)
        }
    }
}
