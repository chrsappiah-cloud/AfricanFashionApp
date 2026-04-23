//
//  BackendAPI.swift
//  AfricanFashionApp
//

import Foundation

enum BackendSecurityError: Error, LocalizedError {
    case insecureScheme
    case hostNotAllowlisted

    var errorDescription: String? {
        switch self {
        case .insecureScheme:
            return "Backend transport must use HTTPS."
        case .hostNotAllowlisted:
            return "Backend host is not in the environment allowlist."
        }
    }
}

enum BackendRetryError: Error {
    case exhausted(lastError: Error)
}

enum BackendAPI {
    static let authLoginPaths = ["v1/auth/login", "auth/login", "login"]
    static let healthPaths = ["health", "healthz", "v1/health", "status"]
    static let defaultUploadProbePath = "/v1/uploads/presign"
    static let requestTimeout: TimeInterval = 12
    static let userAgent = "AfricanFashionApp-iOS/1.0"
    nonisolated(unsafe) static let maxRetryAttempts = 3

    static var allowedHosts: Set<String> {
        var hosts = Set<String>()
        if let overrideHost = AppConfiguration.current.environment.apiBaseURL.host?.lowercased(),
           !overrideHost.isEmpty {
            hosts.insert(overrideHost)
        }
        switch AppConfiguration.current.environment {
        case .development:
            hosts.formUnion(["api.dev.africanfashion.example", "localhost", "127.0.0.1"])
        case .staging:
            hosts.formUnion(["api.staging.africanfashion.example"])
        case .production:
            hosts.formUnion([
                "api.africanfashion.example",
                "africanfashion-api.chrsappiah.workers.dev",
            ])
        }
        return hosts
    }

    static func makeURL(path: String) -> URL {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.hasPrefix("/") ? String(trimmed.dropFirst()) : trimmed
        return AppConfiguration.current.environment.apiBaseURL.appendingPathComponent(normalized)
    }

    static func makeJSONRequest(
        url: URL,
        method: String,
        body: Data? = nil,
        bearerToken: String? = nil
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = requestTimeout
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-ID")
        if let bearerToken, !bearerToken.isEmpty {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    static func validateTransportSecurity(for url: URL) throws {
        if url.scheme?.lowercased() != "https" {
            throw BackendSecurityError.insecureScheme
        }
        let host = (url.host ?? "").lowercased()
        if !allowedHosts.contains(host) {
            throw BackendSecurityError.hostNotAllowlisted
        }
    }

    static func shouldRetry(statusCode: Int) -> Bool {
        statusCode == 408 || statusCode == 429 || (500 ... 599).contains(statusCode)
    }

    static func executeWithRetry<T>(
        maxAttempts: Int = BackendAPI.maxRetryAttempts,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var latestError: Error?
        let attempts = max(1, maxAttempts)
        for attempt in 1 ... attempts {
            do {
                return try await operation()
            } catch {
                latestError = error
                if attempt == attempts { break }
                let backoff = UInt64(pow(2.0, Double(attempt - 1)) * 250_000_000) // 250ms, 500ms, 1s
                try? await Task.sleep(nanoseconds: backoff)
            }
        }
        throw BackendRetryError.exhausted(lastError: latestError ?? URLError(.unknown))
    }
}
