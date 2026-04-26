import SwiftUI
import WebKit

enum WCSPlatformURL {
    /// Resolution order: runtime UserDefaults → `WCSPlatformBaseURL` in Info.plist → local Next.js dev server.
    static var `default`: URL {
        if let s = UserDefaults.standard.string(forKey: "wcs_platform_base_url")?
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
        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.backgroundColor = UIColor(red: 0.05, green: 0.12, blue: 0.23, alpha: 1)
        context.coordinator.webView = web
        context.coordinator.lastReloadToken = reloadToken
        context.coordinator.isLoading = _isLoading
        context.coordinator.loadError = _loadError
        web.load(URLRequest(url: WCSPlatformURL.default))
        return web
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.isLoading = _isLoading
        context.coordinator.loadError = _loadError

        if reloadToken != context.coordinator.lastReloadToken {
            context.coordinator.lastReloadToken = reloadToken
            isLoading = true
            loadError = nil
            webView.reload()
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
            self.loadError?.wrappedValue = error.localizedDescription
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.isLoading?.wrappedValue = false
            self.loadError?.wrappedValue = error.localizedDescription
        }
    }
}
