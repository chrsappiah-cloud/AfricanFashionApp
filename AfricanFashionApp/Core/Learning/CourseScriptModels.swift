//
//  CourseScriptModels.swift
//  AfricanFashionApp
//
//  Sample “course script” lines used to drive module-aligned video discovery (YouTube Data API + embeds).
//  This is not generative video synthesis; it maps authored lesson intents to searchable public media.
//

import Foundation

/// One line in a generated course script (module + lesson scope).
struct CourseLessonScriptLine: Identifiable, Hashable, Sendable {
    let id: String
    let moduleTitle: String
    let lessonTitle: String
    /// Optional curator note from script generation (shown in UI).
    let teachingIntent: String

    /// Query sent to YouTube `search.list` for this lesson (internal + external API boundary).
    var youTubeSearchQuery: String {
        let core = "\(moduleTitle) \(lessonTitle)".trimmingCharacters(in: .whitespacesAndNewlines)
        let intent = teachingIntent.trimmingCharacters(in: .whitespacesAndNewlines)
        if intent.isEmpty {
            return "\(core) documentary craft fashion"
        }
        return "\(core) \(intent)"
    }
}

/// Bundles the canonical demo script shipped with the app build-up phase.
enum CourseScriptSample {
    /// Demo script: heritage craft → global runway literacy (aligns with Wendy's AfricanFash positioning).
    static let wcsFashionHeritageScript: [CourseLessonScriptLine] = [
        CourseLessonScriptLine(
            id: "m1-l1",
            moduleTitle: "Module 1 · Textile literacy",
            lessonTitle: "West African strip weaving vocabulary",
            teachingIntent: "museum open access education"
        ),
        CourseLessonScriptLine(
            id: "m1-l2",
            moduleTitle: "Module 1 · Textile literacy",
            lessonTitle: "Indigo resist dyeing and adire",
            teachingIntent: "documentary masterclass"
        ),
        CourseLessonScriptLine(
            id: "m2-l1",
            moduleTitle: "Module 2 · Runway translation",
            lessonTitle: "Editorial silhouette from wax print",
            teachingIntent: "fashion week runway"
        ),
        CourseLessonScriptLine(
            id: "m2-l2",
            moduleTitle: "Module 2 · Runway translation",
            lessonTitle: "Accessory craft for travel wardrobes",
            teachingIntent: "slow fashion artisan"
        ),
        CourseLessonScriptLine(
            id: "m3-l1",
            moduleTitle: "Module 3 · Scholarly context",
            lessonTitle: "Dress histories in open museum collections",
            teachingIntent: "curatorial lecture"
        ),
    ]
}
