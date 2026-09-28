//
//  Halftime.swift
//  ultimeter
//

import Foundation
import SwiftData

/// The halftime marker.
/// Records the split between the two halves.
@Model
final class Halftime {
    var sequence: Int
    var pointNumber: Int
    var createdAt: Date
    var game: Game?

    init(
        sequence: Int,
        pointNumber: Int,
        createdAt: Date = Date(),
        game: Game? = nil
    ) {
        self.sequence = sequence
        self.pointNumber = pointNumber
        self.createdAt = createdAt
        self.game = game
    }
}
