//
//  PointReducer.swift
//  ultimeter
//

import Foundation

/// State derived from one point's event sequence.
struct PointState {
    let phase: PossessionState
    let holder: Player?
    let puller: Player?
    let hasPull: Bool
    let blockers: [Player]
    let scorer: Player?
    let assist: Player?
    let scoredBy: ScoringTeam?
    let outcome: PointOutcome?
    let lineLocked: Bool

    var isSubbing: Bool { !lineLocked && phase != .none }
}

/// Reduces the ordered event sequence into the current point state.
enum PointReducer {
    static func reduce(
        status: PointStatus,
        start: StartingPosition,
        events: [Event]
    ) -> PointState {
        var reduced = ReducedEvents(status: status, start: start)
        for event in events.sorted(by: { $0.sequence < $1.sequence }) {
            reduced.apply(event)
        }
        let scoredBy = reduced.scoredBy
        return PointState(
            phase: reduced.phase,
            holder: reduced.receiver ?? reduced.pickup,
            puller: reduced.puller,
            hasPull: reduced.hasPull,
            blockers: reduced.blockers,
            scorer: reduced.scorer,
            assist: reduced.assist,
            scoredBy: scoredBy,
            outcome: outcome(status: status, scoredBy: scoredBy, start: start),
            lineLocked: status == .complete || reduced.lineLocked
        )
    }

    private struct ReducedEvents {
        var phase: PossessionState
        var pickup: Player?
        var receiver: Player?
        var puller: Player?
        var hasPull = false
        var blockers: [Player] = []
        var scorer: Player?
        var assist: Player?
        var lastThrower: Player?
        var scoredBy: ScoringTeam?
        var lineLocked = false

        init(status: PointStatus, start: StartingPosition) {
            guard status == .active else {
                phase = .none
                return
            }
            phase = start == .offense ? .awaitingPickup : .defense
        }

        mutating func apply(_ event: Event) {
            phase = PointReducer.advance(phase, on: event.kind)
            switch event.kind {
            case .pull:
                if !hasPull { puller = event.player }
                hasPull = true
                lineLocked = true
            case .pickup:
                pickup = event.player
                lastThrower = nil
            case .pass:
                receiver = event.relatedPlayer
                lastThrower = event.player
            case .block:
                if let player = event.player { blockers.append(player) }
            case .drop, .turnover:
                pickup = nil
                receiver = nil
                lastThrower = nil
            case .score:
                scorer = event.player
                assist = lastThrower
                scoredBy = event.scoringTeam
            case .sub:
                lineLocked = event.substitutionPhase == .completed
            }
        }
    }

    private static func advance(_ phase: PossessionState, on kind: EventKind) -> PossessionState {
        switch (phase, kind) {
        case (.defense, .block), (.defense, .turnover):
            .awaitingPickup
        case (.awaitingPickup, .pickup), (.possession, .pickup):
            .possession
        case (.possession, .turnover), (.possession, .drop):
            .defense
        default:
            phase
        }
    }

    private static func outcome(
        status: PointStatus,
        scoredBy: ScoringTeam?,
        start: StartingPosition
    ) -> PointOutcome? {
        guard status == .complete, let scoredBy else { return nil }
        switch (start, scoredBy) {
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
}

/// Event-derived values exposed by a point.
extension Point {
    var orderedEvents: [Event] {
        events.sorted { $0.sequence < $1.sequence }
    }

    var state: PointState {
        PointReducer.reduce(status: status, start: startingPosition, events: orderedEvents)
    }

    var phase: PossessionState { state.phase }
    var holder: Player? { state.holder }
    var puller: Player? { state.puller }
    var hasPull: Bool { state.hasPull }
    var blockers: [Player] { state.blockers }
    var scorer: Player? { state.scorer }
    var assist: Player? { state.assist }
    var scoredBy: ScoringTeam? { state.scoredBy }
    var outcome: PointOutcome? { state.outcome }
    var lineLocked: Bool { state.lineLocked }
    var nextEventSequence: Int { (events.map(\.sequence).max() ?? -1) + 1 }

    func makeEvent(kind: EventKind) -> Event {
        Event(sequence: nextEventSequence, kind: kind, point: self)
    }
}
