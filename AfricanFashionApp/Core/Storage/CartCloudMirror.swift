//
//  CartCloudMirror.swift
//  AfricanFashionApp
//

import Foundation
import SwiftData

private struct CartLineSnapshot: Codable {
    var productID: UUID
    var title: String
    var quantity: Int
    var currencyCode: String
    var price: Decimal
}

enum CartCloudMirror {
    static func sync(lines: [CartLine], into context: ModelContext) throws {
        let snapshots = lines.map {
            CartLineSnapshot(
                productID: $0.product.id,
                title: $0.product.title,
                quantity: $0.quantity,
                currencyCode: $0.product.currencyCode,
                price: $0.product.price
            )
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshots)
        try CloudBackupRepository.upsert(slug: CloudBackupSlugs.cartSnapshot, payload: data, into: context)
    }
}
