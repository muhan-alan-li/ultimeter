//
//  GameFormViewModel.swift
//  ultimeter
//

import Foundation
import SwiftData

/// Errors thrown by the game form screen.
enum GameFormError: Error, LocalizedError {
    case emptyOpponentName
    case invalidTarget(Int)
    case alreadyStarted
    case saveFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .emptyOpponentName:
            "Opponent name cannot be empty."
        case .invalidTarget(let target):
            "Invalid target \(target). Choose 13, 15, 17, 19, or 21."
        case .alreadyStarted:
            "The game already started. Target changes are not allowed."
        case .saveFailed(let underlying):
            "The game could not be saved. \(underlying.localizedDescription)"
        }
    }
}

/// View model for `GameFormView`. Owns game create and update,
/// including opponent and tournament find-or-create.
@Observable
@MainActor
final class GameFormViewModel {
    private let context: ModelContext
    private let team: Team
    private let game: Game?

    var date: Date
    var opponentName: String
    var tournamentName: String
    var targetPoints: Int
    var startingPosition: StartingPosition
    var isSaving = false

    init(context: ModelContext, team: Team, game: Game? = nil) {
        self.context = context
        self.team = team
        self.game = game
        self.date = game?.date ?? Date()
        self.opponentName = game?.opponent.name ?? ""
        self.tournamentName = game?.tournament?.name ?? ""
        self.targetPoints = game?.targetPoints ?? 15
        self.startingPosition = game?.startingPosition ?? .offense
    }

    var isEditing: Bool { game != nil }

    var trimmedOpponentName: String {
        opponentName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedTournamentName: String {
        tournamentName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Setup controls stay enabled before the game starts only.
    var isSetupEditable: Bool {
        game?.status ?? .scheduled == .scheduled
    }

    private func findOrCreateOpponent(_ name: String) throws -> Opponent {
        let all: [Opponent] = try context.fetch(FetchDescriptor<Opponent>())
        if let existing = all.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            return existing
        }
        let opponent = Opponent(name: name)
        context.insert(opponent)
        return opponent
    }

    private func findOrCreateTournament(_ name: String) -> Tournament? {
        guard !name.isEmpty else { return nil }
        let all: [Tournament] = (try? context.fetch(FetchDescriptor<Tournament>())) ?? []
        if let existing = all.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            return existing
        }
        let tournament = Tournament(name: name)
        context.insert(tournament)
        return tournament
    }

    func saveGame() throws {
        guard !trimmedOpponentName.isEmpty else { throw GameFormError.emptyOpponentName }
        guard Game.allowedTargets.contains(targetPoints) else {
            throw GameFormError.invalidTarget(targetPoints)
        }
        if let game {
            let isSetupChange = targetPoints != game.targetPoints || startingPosition != game.startingPosition
            if isSetupChange {
                guard game.status == .scheduled else { throw GameFormError.alreadyStarted }
            }
        }
        isSaving = true
        defer { isSaving = false }
        do {
            let opponent = try findOrCreateOpponent(trimmedOpponentName)
            let tournament = findOrCreateTournament(trimmedTournamentName)
            if let game {
                game.date = date
                game.opponent = opponent
                game.tournament = tournament
                if targetPoints != game.targetPoints || startingPosition != game.startingPosition {
                    game.targetPoints = targetPoints
                    game.startingPosition = startingPosition
                }
            } else {
                let newGame = Game(
                    date: date,
                    team: team,
                    opponent: opponent,
                    tournament: tournament,
                    targetPoints: targetPoints,
                    startingPosition: startingPosition,
                    status: .scheduled
                )
                context.insert(newGame)
                if !team.games.contains(where: { $0 === newGame }) {
                    team.games.append(newGame)
                }
            }
            try context.save()
        } catch let error as GameFormError {
            context.rollback()
            throw error
        } catch {
            context.rollback()
            throw GameFormError.saveFailed(underlying: error)
        }
    }
}
