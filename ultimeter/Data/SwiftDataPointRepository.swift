//
//  SwiftDataPointRepository.swift
//  ultimeter
//

import Foundation
import SwiftData

/// The SwiftData implementation of the point aggregate.
/// Every method is one guard and one write.
@MainActor
final class SwiftDataPointRepository: PointRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Line

    func toggleLine(_ player: Player, in point: Point) throws {
        let game = try requireGame(of: point)
        try PointRules.check(.toggleLine(player), game: game, point: point)
        let holder = point.holder
        try context.write {
            let wasSubbing = point.status == .active && !point.lineLocked
            if let index = point.line.firstIndex(where: { $0 === player }) {
                point.line.remove(at: index)
                if wasSubbing, LineRules.isComplete(point) {
                    appendSubstitution(.completed, to: point)
                }
                return
            }
            point.line.append(player)
            if point.status == .active, let holder, player !== holder,
                !point.line.contains(where: { $0 === holder }) {
                transferHolder(from: holder, to: player, in: point)
            }
            if wasSubbing, LineRules.isComplete(point) {
                appendSubstitution(.completed, to: point)
            }
        }
    }

    func pruneLine(in point: Point) throws {
        let game = try requireGame(of: point)
        let remaining = LineRules.pruned(point.line, roster: game.team.players)
        guard remaining.count != point.line.count else { return }
        let wasLocked = point.status == .active && point.lineLocked
        guard wasLocked || LineRules.isEditable(point) else { return }
        try context.write {
            point.line = remaining
            if wasLocked { appendSubstitution(.started, to: point) }
        }
    }

    func unlockLine(in point: Point) throws {
        let game = try requireGame(of: point)
        try PointRules.check(.sub, game: game, point: point)
        try context.write {
            appendSubstitution(.started, to: point)
        }
    }

    // MARK: - Pull

    func startPull(in point: Point) throws {
        let game = try requireGame(of: point)
        try PointRules.check(.startPull, game: game, point: point)
        try context.write {
            if point.startingPosition != .defense {
                _ = setEventPlayer(in: point, kind: .pull, to: nil)
            }
            activate(point)
        }
    }

    func pull(in point: Point, by player: Player) throws {
        let game = try requireGame(of: point)
        try PointRules.check(.pull(player), game: game, point: point)
        try context.write {
            _ = setEventPlayer(in: point, kind: .pull, to: player)
            activate(point)
        }
    }

    // MARK: - Disc

    func recordPickup(in point: Point, by player: Player) throws {
        try append(.pickup(player), kind: .pickup, to: point) { event in
            event.player = player
        }
    }

    func recordPass(in point: Point, to receiver: Player) throws {
        let holder = point.holder
        try append(.pass(receiver), kind: .pass, to: point) { event in
            event.player = holder
            event.relatedPlayer = receiver
        }
    }

    func recordDrop(in point: Point, to receiver: Player) throws {
        let holder = point.holder
        try append(.drop(receiver), kind: .drop, to: point) { event in
            event.player = holder
            event.relatedPlayer = receiver
        }
    }

    func recordBlock(in point: Point, by player: Player) throws {
        try append(.block(player), kind: .block, to: point) { event in
            event.player = player
        }
    }

    func recordOurTurnover(in point: Point) throws {
        try append(.ourTurnover, kind: .turnover, to: point) { _ in }
    }

    func recordTheirTurnover(in point: Point) throws {
        try append(.theirTurnover, kind: .turnover, to: point) { event in
            event.turnoverCause = .throwaway
        }
    }

    // MARK: - Undo

    /// Reverts the most recent event of a live point.
    func undoLastEvent(in point: Point) throws {
        let game = try requireGame(of: point)
        try PointRules.check(.undoLastEvent, game: game, point: point)
        guard let event = point.orderedEvents.last(where: {
            PointRules.isUndoable($0.kind)
        }) else { throw AppError.invalidAction }
        try context.write {
            deleteEvent(event, from: point)
        }
    }

    // MARK: - Result

    func scoreByPlayer(_ player: Player, in point: Point) throws {
        let game = try requireGame(of: point)
        try PointRules.check(.score(player), game: game, point: point)
        let holder = point.holder
        try context.write {
            let pass = point.makeEvent(kind: .pass)
            pass.player = holder
            pass.relatedPlayer = player
            pass.isScoringPass = true
            context.insert(pass)
            point.events.append(pass)
            appendScore(player, scoredBy: .us, to: point)
            finish(point, in: game)
        }
    }

    /// Completes a live point, or edits the result of a finished point.
    func recordScore(
        of point: Point,
        in game: Game,
        scoredBy: ScoringTeam
    ) throws {
        try PointRules.checkResult(game, point: point, scoredBy: scoredBy)
        if point.status == .active {
            try context.write {
                appendScore(nil, scoredBy: scoredBy, to: point)
                finish(point, in: game)
            }
            return
        }
        guard point.scoredBy != scoredBy else { return }
        try context.write {
            if let score = scoreEvent(in: point) {
                score.scoringTeam = scoredBy
                if scoredBy == .them {
                    score.player = nil
                    if let scoringPass = point.orderedEvents.last(where: \.isScoringPass) {
                        deleteEvent(scoringPass, from: point)
                    }
                }
            } else {
                appendScore(nil, scoredBy: scoredBy, to: point)
            }
            insertHalftimeIfNeeded(in: game)
            let reachedTarget = GameProgress.reachedTarget(game)
            if game.status == .live && reachedTarget {
                endGame(game)
                return
            }
            if game.status == .ended && !reachedTarget {
                reopenGame(game)
            }
            if let open = game.currentPoint {
                open.startingPosition = GameProgress.side(
                    ofPoint: open.number,
                    in: game
                )
            }
        }
    }

    // MARK: - Result helpers

    /// Marks a point complete and opens the next point.
    private func finish(_ point: Point, in game: Game) {
        point.status = .complete
        guard !GameProgress.reachedTarget(game) else {
            game.status = .ended
            return
        }
        insertHalftimeIfNeeded(in: game)
        insertPoint(in: game, number: GameProgress.nextPointNumber(in: game))
    }

    /// Opens the second half when a score reaches the halftime target.
    private func insertHalftimeIfNeeded(in game: Game) {
        guard GameProgress.isHalftimeReached(game) else { return }
        let number = GameProgress.nextPointNumber(in: game)
        let half = game.makeHalftime(pointNumber: number)
        context.insert(half)
        game.halftime = half
    }

    private func endGame(_ game: Game) {
        for open in game.points.filter({ $0.status != .complete }) {
            game.points.removeAll { $0 === open }
            context.delete(open)
        }
        game.status = .ended
    }

    private func reopenGame(_ game: Game) {
        game.status = .live
        insertPoint(in: game, number: GameProgress.nextPointNumber(in: game))
    }

    private func insertPoint(in game: Game, number: Int) {
        let side = GameProgress.side(ofPoint: number, in: game)
        let point = game.makePoint(number: number, side: side, status: .scheduled)
        context.insert(point)
        game.points.append(point)
    }
}

// MARK: - Event helpers

extension SwiftDataPointRepository {

    /// Moves the disc to the incoming sub when the holder subs out.
    /// Finds the pickup or pass that defines the holder and repoints it.
    /// Runs inside the line write, so the swap stays atomic.
    private func transferHolder(from old: Player, to new: Player, in point: Point) {
        var defining: Event?
        var isPass = false
        for event in point.orderedEvents {
            switch event.kind {
            case .turnover, .drop:
                defining = nil
            case .pickup:
                defining = event
                isPass = false
            case .pass:
                defining = event
                isPass = true
            default:
                break
            }
        }
        guard let defining else { return }
        if isPass {
            defining.relatedPlayer = new
        } else {
            defining.player = new
        }
    }

    private func activate(_ point: Point) {
        point.status = .active
    }

    private func appendSubstitution(_ phase: SubstitutionPhase, to point: Point) {
        let event = point.makeEvent(kind: .sub)
        event.substitutionPhase = phase
        context.insert(event)
        point.events.append(event)
    }

    private func appendScore(_ player: Player?, scoredBy: ScoringTeam, to point: Point) {
        let event = point.makeEvent(kind: .score)
        event.player = player
        event.scoringTeam = scoredBy
        context.insert(event)
        point.events.append(event)
    }

    /// Guards one append action, then adds the event in one write.
    private func append(
        _ action: PointAction,
        kind: EventKind,
        to point: Point,
        configure: (Event) -> Void
    ) throws {
        let game = try requireGame(of: point)
        try PointRules.check(action, game: game, point: point)
        try context.write {
            let event = point.makeEvent(kind: kind)
            configure(event)
            context.insert(event)
            point.events.append(event)
        }
    }

    private func setEventPlayer(
        in point: Point,
        kind: EventKind,
        to player: Player?
    ) -> Event {
        if let existing = point.orderedEvents.first(where: { $0.kind == kind }) {
            existing.player = player
            return existing
        }
        let event = point.makeEvent(kind: kind)
        event.player = player
        context.insert(event)
        point.events.append(event)
        return event
    }

    private func scoreEvent(in point: Point) -> Event? {
        point.orderedEvents.first { $0.kind == .score }
    }

    private func deleteEvent(_ event: Event, from point: Point) {
        point.events.removeAll { $0 === event }
        context.delete(event)
    }

    private func requireGame(of point: Point) throws -> Game {
        guard let game = point.game, game.points.contains(where: { $0 === point }) else {
            throw AppError.detachedPoint
        }
        return game
    }
}
