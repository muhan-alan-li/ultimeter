//
//  Point.swift
//  ultimeter
//

import Foundation
import SwiftData

/// The status of a point.
enum PointStatus: String, Codable {
    case active
    case complete
}

/// The team that won a point.
enum ScoringTeam: String, Codable {
    // swiftlint:disable:next identifier_name - plan-points.md requires `us`/`them`.
    case us
    case them

    /// The name of the scoring team in this game.
    func teamName(in game: Game) -> String {
        switch self {
        case .us: game.team.name
        case .them: game.opponent.name
        }
    }
}

/// One played point. A game event.
/// Stores only data for one point.
@Model
final class Point: GameEvent {
    var sequence: Int
    var number: Int
    var status: PointStatus
    var startingPosition: StartingPosition
    var scoredBy: ScoringTeam?
    var createdAt: Date
    var game: Game?

    var kind: GameEventKind { .point }

    init(
        sequence: Int,
        number: Int,
        status: PointStatus = .active,
        startingPosition: StartingPosition,
        scoredBy: ScoringTeam? = nil,
        createdAt: Date = Date(),
        game: Game? = nil
    ) {
        self.sequence = sequence
        self.number = number
        self.status = status
        self.startingPosition = startingPosition
        self.scoredBy = scoredBy
        self.createdAt = createdAt
        self.game = game
    }
}
