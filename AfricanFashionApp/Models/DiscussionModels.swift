//
//  DiscussionModels.swift
//  AfricanFashionApp
//

import Foundation

struct DiscussionChannel: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let subtitle: String
}

struct DiscussionThread: Identifiable, Codable, Hashable {
    let id: UUID
    let channelID: String
    let authorName: String
    let authorRole: String
    let title: String
    let message: String
    let postedAt: Date
    let replyCount: Int
    let likeCount: Int
    let isPinned: Bool
}

struct DiscussionFeedPayload: Codable {
    let channels: [DiscussionChannel]
    let threads: [DiscussionThread]
}

struct CreateDiscussionThreadRequest: Codable {
    let channelID: String
    let title: String
    let message: String
}

struct APIPipelineStatus: Codable, Hashable {
    let api: Bool
    let middleware: Bool
    let realtime: Bool
    let database: Bool
    let message: String
    let checkedAt: Date
}
