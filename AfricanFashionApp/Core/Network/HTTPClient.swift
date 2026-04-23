//
//  HTTPClient.swift
//  AfricanFashionApp
//

import Foundation
import CryptoKit
import Security

enum APIError: Error, LocalizedError {
    case invalidURL
    case transport(underlying: Error)
    case status(code: Int, body: Data?)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The request URL was invalid."
        case .transport(let underlying):
            underlying.localizedDescription
        case .status(let code, _):
            "The server returned status code \(code)."
        }
    }
}

protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    nonisolated init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            let delegate = TLSPinningDelegate(configuration: .default)
            self.session = URLSession(
                configuration: config,
                delegate: delegate,
                delegateQueue: nil
            )
        }
    }

    nonisolated func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

private final class TLSPinningDelegate: NSObject, URLSessionDelegate {
    struct Configuration: Sendable {
        /// Hosts we care about for pinning policy.
        var monitoredHosts: Set<String>
        /// SHA256 hashes (base64) of DER certificates for each host.
        /// Keep at least 2 active pins during rotations.
        var certificatePinsByHost: [String: Set<String>]
        /// When true, hosts listed in `monitoredHosts` must also match a pin.
        var requirePinForMonitoredHosts: Bool

        static let `default` = Configuration(
            monitoredHosts: [
                "api.africanfashion.example",
                "api.staging.africanfashion.example",
                "africanfashion-api.chrsappiah.workers.dev",
            ],
            certificatePinsByHost: [
                "api.africanfashion.example": [],
                "api.staging.africanfashion.example": [],
                "africanfashion-api.chrsappiah.workers.dev": [],
            ],
            // Keep this permissive until real pins are generated and rotated in config.
            requirePinForMonitoredHosts: false
        )
    }

    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
        super.init()
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host.lowercased()
        var trustError: CFError?
        guard SecTrustEvaluateWithError(trust, &trustError) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Optional pinning hook: enforce only when pins are configured or policy explicitly requires it.
        if configuration.monitoredHosts.contains(host) {
            let expectedPins = configuration.certificatePinsByHost[host] ?? []
            if expectedPins.isEmpty {
                if configuration.requirePinForMonitoredHosts {
                    completionHandler(.cancelAuthenticationChallenge, nil)
                    return
                }
            } else if !matchesAnyPinnedCertificateHash(trust: trust, expectedPins: expectedPins) {
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
        }

        completionHandler(.useCredential, URLCredential(trust: trust))
    }

    private func matchesAnyPinnedCertificateHash(trust: SecTrust, expectedPins: Set<String>) -> Bool {
        guard let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate], !chain.isEmpty else {
            return false
        }
        for cert in chain {
            let certData = SecCertificateCopyData(cert) as Data
            let digest = SHA256.hash(data: certData)
            let hash = Data(digest).base64EncodedString()
            if expectedPins.contains(hash) {
                return true
            }
        }
        return false
    }
}
