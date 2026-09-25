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

/// The possession state of a live point.
/// Derived by folding the event log in order.
/// Supports unlimited turnover alternation.
enum PossessionState: String, Codable {
    case none
    case defense
    case awaitingPickup
    case possession

    /// The name shown in the user interface.
    var displayName: String {
        switch self {
        case .none: "No possession"
        case .defense: "Defense"
        case .awaitingPickup: "Loose disc"
        case .possession: "Our disc"
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

    /// Possession state folded from the event log in order.
    /// A turnover while we hold gives them the disc.
    /// A turnover while they hold leaves it loose.
    /// A block leaves it loose with credit.
    var phase: PossessionState {
        guard status == .active else { return .none }
        var phase: PossessionState =
            startingPosition == .offense ? .awaitingPickup : .defense
        for stat in orderedStats {
            switch stat.kind {
            case .pull, .goal, .pass:
                break
            case .block:
                if phase == .defense { phase = .awaitingPickup }
            case .pickup:
                if phase == .awaitingPickup || phase == .possession {
                    phase = .possession
                }
            case .turnover:
                if phase == .possession {
                    phase = .defense
                } else if phase == .defense {
                    phase = .awaitingPickup
                }
            case .drop:
                if phase == .possession { phase = .defense }
            }
        }
        return phase
    }

    /// Event log for this point. Mirrors how a game holds points.
    @Relationship(deleteRule: .cascade, inverse: \Stat.point)
    var stats: [Stat] = []

    var nextStatSequence: Int = 0

    /// Stats sorted by insertion order.
    var orderedStats: [Stat] {
        stats.sorted { $0.sequence < $1.sequence }
    }

    /// Our puller, if we pulled this point.
    var puller: Player? {
        orderedStats.first { $0.kind == .pull }?.player
    }

    /// Our blockers in order. Stacks over stands.
    var blockers: [Player] {
        orderedStats.filter { $0.kind == .block }.compactMap(\.player)
    }

    /// The player holding the disc, if we hold it.
    /// Folds the log in order. Each turnover resets possession.
    /// Uses the last pass receiver since then, else the pickup player.
    var holder: Player? {
        var pickup: Player?
        var receiver: Player?
        for stat in orderedStats {
            switch stat.kind {
            case .turnover, .drop:
                pickup = nil
                receiver = nil
            case .pickup:
                pickup = stat.player
            case .pass:
                receiver = stat.relatedPlayer
            default:
                break
            }
        }
        return receiver ?? pickup
    }

    /// Count of passes logged on this point.
    var passCount: Int {
        orderedStats.filter { $0.kind == .pass }.count
    }

    /// Count of drops logged on this point.
    var dropCount: Int {
        orderedStats.filter { $0.kind == .drop }.count
    }

    /// Our scorer, if we scored this point.
    var scorer: Player? {
        orderedStats.first { $0.kind == .goal }?.player
    }

    /// Build the next stat and advance the sequence counter.
    /// Caller inserts the result into the context and appends it to `stats`.
    func makeStat(kind: StatKind) -> Stat {
        let stat = Stat(sequence: nextStatSequence, kind: kind, point: self)
        nextStatSequence += 1
        return stat
    }

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
