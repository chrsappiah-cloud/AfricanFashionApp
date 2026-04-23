//
//  AuthAPIClient.swift
//  AfricanFashionApp
//

import Foundation

struct AuthSession: Sendable {
    var accessToken: String
    var displayName: String
    var email: String
}

enum AuthAPIError: Error, LocalizedError {
    case invalidCredentials
    case invalidInput
    case responseDecodingFailed
    case noAuthEndpointResponded
    case server(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password."
        case .invalidInput:
            return "Enter a valid email and password (8+ characters)."
        case .responseDecodingFailed:
            return "Could not decode sign-in response."
        case .noAuthEndpointResponded:
            return "Could not reach authentication endpoint."
        case .server(let message):
            return message
        }
    }
}

enum AuthAPIClient {
    private struct LoginRequestBody: Encodable {
        var email: String
        var password: String
    }

    private struct LoginResponse: Decodable {
        struct UserPayload: Decodable {
            var email: String?
            var displayName: String?
            var name: String?
        }

        var accessToken: String?
        var token: String?
        var jwt: String?
        var user: UserPayload?
        var displayName: String?
        var name: String?
        var message: String?
    }

    private struct ServerErrorEnvelope: Decodable {
        var message: String?
        var error: String?
    }

    static func signIn(
        email: String,
        password: String,
        http: HTTPClient = URLSessionHTTPClient()
    ) async throws -> AuthSession {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanEmail.contains("@"), password.count >= 8 else {
            throw AuthAPIError.invalidInput
        }
        let body = LoginRequestBody(email: cleanEmail, password: password)
        let endpoints = BackendAPI.authLoginPaths

        for path in endpoints {
            let endpoint = BackendAPI.makeURL(path: path)
            try BackendAPI.validateTransportSecurity(for: endpoint)
            let requestBody = try JSONEncoder().encode(body)
            let request = BackendAPI.makeJSONRequest(url: endpoint, method: "POST", body: requestBody)

            do {
                let (data, response) = try await BackendAPI.executeWithRetry {
                    let (data, response) = try await http.data(for: request)
                    if let http = response as? HTTPURLResponse, BackendAPI.shouldRetry(statusCode: http.statusCode) {
                        throw APIError.status(code: http.statusCode, body: data)
                    }
                    return (data, response)
                }
                guard let http = response as? HTTPURLResponse else {
                    continue
                }

                if http.statusCode == 401 || http.statusCode == 403 {
                    throw AuthAPIError.invalidCredentials
                }
                guard (200 ..< 300).contains(http.statusCode) else {
                    let message = decodeServerError(from: data) ?? "Authentication failed."
                    throw AuthAPIError.server(message: message)
                }

                guard let decoded = try? JSONDecoder().decode(LoginResponse.self, from: data) else {
                    throw AuthAPIError.responseDecodingFailed
                }

                let token = decoded.accessToken ?? decoded.token ?? decoded.jwt
                guard let token, !token.isEmpty else {
                    throw AuthAPIError.responseDecodingFailed
                }
                let fallbackName = cleanEmail.split(separator: "@").first.map(String.init) ?? "Guest"
                let userPayload = decoded.user
                let userPayloadName = userPayload?.displayName ?? userPayload?.name
                let responseTopLevelName = decoded.displayName ?? decoded.name
                let name = userPayloadName ?? responseTopLevelName ?? fallbackName
                let responseEmail = decoded.user?.email ?? cleanEmail
                return AuthSession(accessToken: token, displayName: name, email: responseEmail)
            } catch let error as AuthAPIError {
                throw error
            } catch let retryError as BackendRetryError {
                if case let .exhausted(lastError) = retryError, let api = lastError as? APIError,
                   case let .status(code, body) = api, code == 401 || code == 403 {
                    let message = body.flatMap(decodeServerError(from:)) ?? "Invalid email or password."
                    throw AuthAPIError.server(message: message)
                }
                continue
            } catch {
                continue
            }
        }

        throw AuthAPIError.noAuthEndpointResponded
    }

    private static func decodeServerError(from data: Data) -> String? {
        if let decoded = try? JSONDecoder().decode(ServerErrorEnvelope.self, from: data) {
            return decoded.message ?? decoded.error
        }
        return String(data: data, encoding: .utf8)
    }
}
