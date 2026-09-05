//
//  Halftime.swift
//  ultimeter
//

import Foundation
import SwiftData

/// The halftime marker. A game event.
/// Records the split between the two halves.
@Model
final class Halftime: GameEvent {
    var sequence: Int
    var pointNumber: Int
    var createdAt: Date
    var game: Game?

    var kind: GameEventKind { .halftime }

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
