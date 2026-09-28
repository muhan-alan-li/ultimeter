//
//  PointFold.swift
//  ultimeter
//

import Foundation

/// One event of a point log, reduced to the data a fold needs.
struct PointEvent {
    let kind: StatKind
    let player: Player?
    let relatedPlayer: Player?
}

/// Pure folds over a point log.
/// These functions touch no container. A test needs no store.
enum PointFold {
    /// The possession state folded from the log in order.
    /// A turnover while we hold gives them the disc.
    /// A turnover while they hold leaves it loose.
    /// A block leaves it loose with credit.
    static func phase(
        status: PointStatus,
        start: StartingPosition,
        events: [PointEvent]
    ) -> PossessionState {
        guard status == .active else { return .none }
        var phase: PossessionState = start == .offense ? .awaitingPickup : .defense
        for event in events {
            phase = advance(phase, on: event.kind)
        }
        return phase
    }

    /// The next possession state after one event.
    private static func advance(
        _ phase: PossessionState,
        on kind: StatKind
    ) -> PossessionState {
        switch (phase, kind) {
        case (.defense, .block), (.defense, .turnover):
            return .awaitingPickup
        case (.awaitingPickup, .pickup), (.possession, .pickup):
            return .possession
        case (.possession, .turnover), (.possession, .drop):
            return .defense
        default:
            return phase
        }
    }

    /// The player holding the disc, if we hold it.
    /// Each turnover resets possession. Uses the last pass receiver
    /// since then, else the pickup player.
    static func holder(_ events: [PointEvent]) -> Player? {
        var pickup: Player?
        var receiver: Player?
        for event in events {
            switch event.kind {
            case .turnover, .drop:
                pickup = nil
                receiver = nil
            case .pickup:
                pickup = event.player
            case .pass:
                receiver = event.relatedPlayer
            default:
                break
            }
        }
        return receiver ?? pickup
    }

    /// Our puller, if we pulled this point.
    static func puller(_ events: [PointEvent]) -> Player? {
        events.first { $0.kind == .pull }?.player
    }

    /// Whether the point has a pull. Our own offense points have a pull
    /// with no player, because they pulled.
    static func hasPull(_ events: [PointEvent]) -> Bool {
        events.contains { $0.kind == .pull }
    }

    /// Our blockers in order. Stacks over stands.
    static func blockers(_ events: [PointEvent]) -> [Player] {
        events.filter { $0.kind == .block }.compactMap(\.player)
    }

    /// Our scorer, if we scored this point.
    static func scorer(_ events: [PointEvent]) -> Player? {
        events.first { $0.kind == .goal }?.player
    }

    /// Count of passes logged on this point.
    static func passCount(_ events: [PointEvent]) -> Int {
        events.filter { $0.kind == .pass }.count
    }

    /// Count of drops logged on this point.
    static func dropCount(_ events: [PointEvent]) -> Int {
        events.filter { $0.kind == .drop }.count
    }

    /// The outcome of this point, if it is complete.
    static func outcome(
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
