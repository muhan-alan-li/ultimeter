//
//  Stat.swift
//  ultimeter
//

import Foundation
import SwiftData

/// The kind of a stat event in a point log.
enum StatKind: String, Codable {
    case pull
    case block
    case pickup
    case pass
    case drop
    case turnover
    case goal
}

/// One event in a point log.
/// `player` is the holder or actor. `relatedPlayer` is the receiver for pass and drop.
@Model
final class Stat {
    var sequence: Int
    var createdAt: Date
    var kind: StatKind
    var player: Player?
    var relatedPlayer: Player?
    var point: Point?

    init(
        sequence: Int,
        kind: StatKind,
        player: Player? = nil,
        relatedPlayer: Player? = nil,
        createdAt: Date = Date(),
        point: Point? = nil
    ) {
        self.sequence = sequence
        self.kind = kind
        self.player = player
        self.relatedPlayer = relatedPlayer
        self.createdAt = createdAt
        self.point = point
    }
}
