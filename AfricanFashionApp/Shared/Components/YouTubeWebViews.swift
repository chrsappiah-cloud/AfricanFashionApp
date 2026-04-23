//
//  YouTubeWebViews.swift
//  AfricanFashionApp
//

import SwiftUI
import WebKit

/// Loads the mobile YouTube **search results** page so users see real runway, market, and accessory videos
/// without a Data API key. Playback stays on YouTube inside the web view.
struct YouTubeSearchResultsWebView: UIViewRepresentable {
    var searchQuery: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        context.coordinator.lastLoadedQuery = nil
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.lastLoadedQuery != searchQuery else { return }
        context.coordinator.lastLoadedQuery = searchQuery
        var components = URLComponents(string: "https://m.youtube.com/results")!
        components.queryItems = [
            URLQueryItem(name: "search_query", value: searchQuery),
        ]
        guard let url = components.url else { return }
        webView.load(URLRequest(url: url))
    }

    final class Coordinator: NSObject {
        var lastLoadedQuery: String?
    }
}

/// Inline embed for a single known video id (used when Data API returns ids).
struct YouTubeEmbedWebView: UIViewRepresentable {
    let videoID: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        return WKWebView(frame: .zero, configuration: configuration)
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let safeID = Self.sanitizedVideoID(videoID) else { return }
        guard context.coordinator.lastID != safeID else { return }
        context.coordinator.lastID = safeID
        let html = """
        <!DOCTYPE html><html><head><meta name=viewport content="width=device-width, initial-scale=1">
        <style>body{margin:0;background:#000}iframe{border:0;width:100%;height:100%;position:absolute;top:0;left:0}</style>
        </head><body>
        <iframe src="https://www.youtube.com/embed/\(safeID)?playsinline=1&modestbranding=1" \
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" \
        allowfullscreen></iframe>
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
    }

    /// YouTube video ids use a constrained alphabet; reject anything else so we never interpolate raw user/HTML.
    private static func sanitizedVideoID(_ raw: String) -> String? {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")
        guard raw.count == 11, raw.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return nil }
        return raw
    }

    final class Coordinator: NSObject {
        var lastID: String?
    }
}
