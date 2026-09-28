//
//  SwiftDataGameRepository.swift
//  ultimeter
//

import Foundation
import SwiftData

/// The SwiftData implementation of the game aggregate.
@MainActor
final class SwiftDataGameRepository: GameRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func saveGame(_ draft: GameDraft, for team: Team, editing game: Game?) throws {
        let opponentName = draft.opponentName
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let tournamentName = draft.tournamentName
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !opponentName.isEmpty else {
            throw AppError.emptyName(field: "Opponent name")
        }
        guard Game.validTargetRange.contains(draft.targetPoints) else {
            throw AppError.invalidTarget(draft.targetPoints)
        }
        if let game, isSetupChange(draft, game: game) {
            guard GameProgress.isSetupEditable(game) else {
                throw AppError.alreadyStarted
            }
        }
        let opponent = try findOrCreateOpponent(opponentName)
        let tournament = try findOrCreateTournament(tournamentName)
        try context.write {
            if let game {
                game.date = draft.date
                game.opponent = opponent
                game.tournament = tournament
                if isSetupChange(draft, game: game) {
                    game.targetPoints = draft.targetPoints
                    game.startingPosition = draft.startingPosition
                }
            } else {
                let newGame = Game(
                    date: draft.date,
                    team: team,
                    opponent: opponent,
                    tournament: tournament,
                    targetPoints: draft.targetPoints,
                    startingPosition: draft.startingPosition,
                    status: .scheduled
                )
                context.insert(newGame)
                if !team.games.contains(where: { $0 === newGame }) {
                    team.games.append(newGame)
                }
            }
        }
    }

    func delete(_ game: Game) throws {
        try context.write {
            context.delete(game)
        }
    }

    func start(_ game: Game) throws {
        guard game.status == .scheduled else { throw AppError.notScheduled }
        guard game.points.isEmpty else { throw AppError.alreadyStarted }
        guard Game.validTargetRange.contains(game.targetPoints) else {
            throw AppError.invalidTarget(game.targetPoints)
        }
        try context.write {
            game.halftimeTarget = GameProgress.halfTarget(of: game)
            let point = game.makePoint(
                number: 1,
                side: game.startingPosition,
                status: .scheduled
            )
            context.insert(point)
            game.points.append(point)
            game.status = .live
        }
    }

    func setCap(_ game: Game, to cap: Int) throws {
        guard game.status == .live else { throw AppError.notLive }
        let minimum = GameProgress.capLowerBound(of: game)
        guard (minimum ... Game.validTargetRange.upperBound).contains(cap) else {
            throw AppError.invalidTarget(cap)
        }
        try context.write {
            game.targetPoints = cap
        }
    }

    func end(_ game: Game, ourScore: Int, theirScore: Int) throws {
        guard game.status == .live else { throw AppError.notLive }
        guard ourScore >= 0, theirScore >= 0 else { throw AppError.invalidScore }
        guard ourScore >= game.ourScore, theirScore >= game.theirScore else {
            throw AppError.finalScoreBelowCurrent
        }
        try context.write {
            removeOpenPoints(from: game)
            let addedUs = ourScore - game.ourScore
            let addedThem = theirScore - game.theirScore
            guard addedUs > 0 || addedThem > 0 else {
                game.status = .ended
                return
            }
            var number = GameProgress.nextPointNumber(in: game)
            for _ in 0 ..< addedUs {
                appendScoredPoint(to: game, number: number, scoredBy: .us)
                number += 1
            }
            for _ in 0 ..< addedThem {
                appendScoredPoint(to: game, number: number, scoredBy: .them)
                number += 1
            }
            game.status = .ended
        }
    }

    // MARK: - Helpers

    private func isSetupChange(_ draft: GameDraft, game: Game) -> Bool {
        draft.targetPoints != game.targetPoints
            || draft.startingPosition != game.startingPosition
    }

    private func findOrCreateOpponent(_ name: String) throws -> Opponent {
        let all = try context.fetch(FetchDescriptor<Opponent>())
        if let existing = all.first(where: {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }) {
            return existing
        }
        let opponent = Opponent(name: name)
        context.insert(opponent)
        return opponent
    }

    private func findOrCreateTournament(_ name: String) throws -> Tournament? {
        guard !name.isEmpty else { return nil }
        let all = try context.fetch(FetchDescriptor<Tournament>())
        if let existing = all.first(where: {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }) {
            return existing
        }
        let tournament = Tournament(name: name)
        context.insert(tournament)
        return tournament
    }

    private func removeOpenPoints(from game: Game) {
        for open in game.points.filter({ $0.status != .complete }) {
            game.points.removeAll { $0 === open }
            context.delete(open)
        }
    }

    private func appendScoredPoint(to game: Game, number: Int, scoredBy: ScoringTeam) {
        let side = GameProgress.side(ofPoint: number, in: game)
        let point = game.makePoint(number: number, side: side, status: .complete)
        let score = point.makeEvent(kind: .score)
        score.scoringTeam = scoredBy
        context.insert(point)
        context.insert(score)
        point.events.append(score)
        game.points.append(point)
    }
}
