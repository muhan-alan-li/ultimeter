//
//  Event.swift
//  ultimeter
//

import Foundation
import SwiftData

/// One action in a point's ordered event log.
@Model
final class Event {
    var sequence: Int
    var createdAt: Date
    var kind: EventKind

    /// The player who acts, throws, receives, pulls, or scores, as the kind requires.
    var player: Player?

    /// The receiver of a pass or drop, or the outgoing player in a substitution.
    var relatedPlayer: Player?

    /// The winner recorded by a score event.
    var scoringTeam: ScoringTeam?

    /// The reason for a turnover, when known.
    var turnoverCause: TurnoverCause?

    /// The result of a pull, when known.
    var pullOutcome: PullOutcome?

    /// True when a pass event is the scoring throw created with a score action.
    var isScoringPass: Bool = false

    /// The start or end marker for a substitution interval.
    var substitutionPhase: SubstitutionPhase?

    var point: Point?

    init(
        sequence: Int,
        kind: EventKind,
        player: Player? = nil,
        relatedPlayer: Player? = nil,
        scoringTeam: ScoringTeam? = nil,
        turnoverCause: TurnoverCause? = nil,
        pullOutcome: PullOutcome? = nil,
        isScoringPass: Bool = false,
        substitutionPhase: SubstitutionPhase? = nil,
        createdAt: Date = Date(),
        point: Point? = nil
    ) {
        self.sequence = sequence
        self.createdAt = createdAt
        self.kind = kind
        self.player = player
        self.relatedPlayer = relatedPlayer
        self.scoringTeam = scoringTeam
        self.turnoverCause = turnoverCause
        self.pullOutcome = pullOutcome
        self.isScoringPass = isScoringPass
        self.substitutionPhase = substitutionPhase
        self.point = point
    }
}
