//
//  Point.swift
//  ultimeter
//

import Foundation
import SwiftData

/// The status of a point.
enum PointStatus: String, Codable {
    case scheduled
    case active
    case complete

    var displayName: String {
        switch self {
        case .scheduled: "Scheduled"
        case .active: "Live"
        case .complete: "Complete"
        }
    }
}

/// The possession state of a live point, derived from its event sequence.
enum PossessionState: String, Codable {
    case none
    case defense
    case awaitingPickup
    case possession
}

/// The result of a completed point from our perspective.
enum PointOutcome {
    case weHold
    case weBreak
    case theyHold
    case theyBreak

    var label: String {
        switch self {
        case .weHold: "We hold"
        case .weBreak: "We break"
        case .theyHold: "They hold"
        case .theyBreak: "They break"
        }
    }
}

/// The team that won a point.
enum ScoringTeam: String, Codable {
    // swiftlint:disable:next identifier_name - keeps the game-side API concise.
    case us
    case them

    func teamName(in game: Game) -> String {
        switch self {
        case .us: game.team.name
        case .them: game.opponent.name
        }
    }
}

/// One played point and its ordered event log.
@Model
final class Point {
    var sequence: Int
    var number: Int
    var status: PointStatus
    var startingPosition: StartingPosition
    var createdAt: Date
    var game: Game?
    var line: [Player] = []

    @Relationship(deleteRule: .cascade, inverse: \Event.point)
    var events: [Event] = []

    init(
        sequence: Int,
        number: Int,
        status: PointStatus = .scheduled,
        startingPosition: StartingPosition,
        createdAt: Date = Date(),
        game: Game? = nil
    ) {
        self.sequence = sequence
        self.number = number
        self.status = status
        self.startingPosition = startingPosition
        self.createdAt = createdAt
        self.game = game
    }
}
