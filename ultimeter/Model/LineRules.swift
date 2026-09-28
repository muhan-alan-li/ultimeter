//
//  LineRules.swift
//  ultimeter
//

import Foundation

/// The rules of a point line.
enum LineRules {
    /// The number of players on a line.
    static let size = 7

    /// Players sorted by name for display and selection.
    static func sorted(_ players: [Player]) -> [Player] {
        players.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    /// The roster of the game team, sorted by name.
    static func roster(of game: Game) -> [Player] {
        sorted(game.team.players)
    }

    /// Whether the line can change. Scheduled points are open.
    /// Active points are open only after a sub.
    static func isEditable(_ point: Point) -> Bool {
        if point.status == .scheduled { return true }
        if point.status == .active { return !point.lineLocked }
        return false
    }

    /// Whether the line has the full number of players.
    static func isComplete(_ point: Point) -> Bool {
        point.line.count == size
    }

    /// Drops line players who are no longer on the roster.
    static func pruned(_ line: [Player], roster: [Player]) -> [Player] {
        line.filter { lined in
            roster.contains { $0 === lined }
        }
    }
}
