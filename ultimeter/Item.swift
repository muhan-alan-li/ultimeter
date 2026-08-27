//
//  Item.swift
//  ultimeter
//
//  Created by Muhan Li on 2026-08-26.
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
