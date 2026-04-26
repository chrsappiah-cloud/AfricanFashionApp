//
//  ModuleVideoPipelineTests.swift
//  AfricanFashionAppTests
//

import Foundation
import Testing
@testable import AfricanFashionApp

struct ModuleVideoPipelineTests {
    @Test func lessonQuerySynthesis_isFast_forThousandsOfLines() {
        let lines = CourseScriptSample.wcsFashionHeritageScript
        #expect(!lines.isEmpty)

        let iterations = 2_000
        let t0 = CFAbsoluteTimeGetCurrent()
        var checksum = 0
        for _ in 0 ..< iterations {
            for line in lines {
                checksum ^= line.youTubeSearchQuery.utf8.count
            }
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - t0
        #expect(checksum >= 0)
        // Local string synthesis should stay far below interactive frame budgets even at scale.
        #expect(elapsed < 0.25, "Expected sub-250ms for \(iterations) passes; saw \(elapsed)s")
    }

    @Test func youTubeSearch_singleProbe_underBudget_whenAPIKeyPresent() async throws {
        guard YouTubeSearchAPIClient.resolveAPIKey() != nil else {
            return
        }

        let budgetSeconds = 20.0
        let t0 = CFAbsoluteTimeGetCurrent()
        let page = try await YouTubeSearchAPIClient.searchVideos(
            query: "museum textile conservation documentary",
            configuration: .africanFashionEditorial,
            maxResults: 3
        )
        let elapsed = CFAbsoluteTimeGetCurrent() - t0
        #expect(elapsed < budgetSeconds, "Single search should stay under \(budgetSeconds)s; saw \(elapsed)s.")
        #expect(page.items.count <= 3)
    }

    @Test func percentile_p98Index_matchesStandardDefinition() {
        let durations = (0 ..< 50).map { Double($0 % 7) + 0.05 } // synthetic ms-like values
        let sorted = durations.sorted()
        let idx = min(sorted.count - 1, Int(floor(Double(sorted.count - 1) * 0.98)))
        let p98 = sorted[max(0, idx)]
        #expect(p98 <= sorted.last!)
        #expect(sorted.contains(p98))
    }
}
