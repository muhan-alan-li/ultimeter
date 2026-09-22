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

    /// The name shown in the user interface.
    var displayName: String {
        switch self {
        case .scheduled: "Scheduled"
        case .active: "Live"
        case .complete: "Complete"
        }
    }
}

/// The result of a completed point from our perspective.
enum PointOutcome {
    /// We started on offense and scored.
    case weHold
    /// We started on defense and scored.
    case weBreak
    /// The opponent started on offense and scored.
    case theyHold
    /// The opponent started on defense and scored.
    case theyBreak

    /// The display label for this outcome.
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

/// One played point.
/// Stores only data for one point.
@Model
final class Point {
    var sequence: Int
    var number: Int
    var status: PointStatus
    var startingPosition: StartingPosition
    var scoredBy: ScoringTeam?
    var createdAt: Date
    var game: Game?
    var line: [Player] = []

    /// Whether the line is locked. Pull locks it, Sub unlocks it.
    var lineLocked: Bool = false

    /// The outcome of this point, if it is complete.
    var outcome: PointOutcome? {
        guard status == .complete, let scoredBy else { return nil }
        switch (startingPosition, scoredBy) {
            case (.offense, .us):
                return .weHold
            case (.defense, .us):
                return .weBreak
            case (.offense, .them):
                return .theyBreak
            case (.defense, .them):
                return .theyHold
        }
    }

    init(
        sequence: Int,
        number: Int,
        status: PointStatus = .scheduled,
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
