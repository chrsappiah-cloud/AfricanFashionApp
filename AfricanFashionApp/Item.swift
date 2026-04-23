//
//  Item.swift
//  AfricanFashionApp
//
//  Created by Christopher Appiah-Thompson  on 23/4/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
