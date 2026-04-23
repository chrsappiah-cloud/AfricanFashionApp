//
//  URLValidator.swift
//  AfricanFashionApp
//

import Foundation

enum URLValidator: Sendable {
    nonisolated static func isAllowedHTTPURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "https" || scheme == "http"
    }
}
