//
//  ModuleVideoDiscoveryPipeline.swift
//  AfricanFashionApp
//
//  Resolves each scripted lesson to playable YouTube results via the Data API (external) and native embeds (internal).
//

import Foundation

/// One lesson’s resolved playable candidates after `search.list`.
struct LessonVideoDiscoveryResult: Identifiable, Hashable, Sendable {
    let scriptLine: CourseLessonScriptLine
    let snippets: [YouTubeVideoSnippet]

    var id: String { scriptLine.id }
}

enum ModuleVideoDiscoveryPipeline {
    /// Runs sequential searches to stay under YouTube quota; suitable for a small scripted module set.
    static func resolveLessonVideos(
        scriptLines: [CourseLessonScriptLine],
        maxResultsPerLesson: Int = 3,
        configuration: YouTubeSearchConfiguration = .africanFashionEditorial,
        http: HTTPClient = URLSessionHTTPClient()
    ) async throws -> [LessonVideoDiscoveryResult] {
        guard YouTubeSearchAPIClient.resolveAPIKey() != nil else {
            throw YouTubeAPIError.missingAPIKey
        }

        var results: [LessonVideoDiscoveryResult] = []
        results.reserveCapacity(scriptLines.count)

        for line in scriptLines {
            let page = try await YouTubeSearchAPIClient.searchVideos(
                query: line.youTubeSearchQuery,
                configuration: configuration,
                maxResults: maxResultsPerLesson,
                http: http
            )
            results.append(LessonVideoDiscoveryResult(scriptLine: line, snippets: page.items))
        }

        return results
    }
}
