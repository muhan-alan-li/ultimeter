//
//  Tournament.swift
//  ultimeter
//

import Foundation
import SwiftData

/// An event where several teams play each other.
@Model
final class Tournament {
    @Attribute(.unique)
    var name: String
    var games: [Game] = []

    init(name: String) {
        self.name = name
    }
}
