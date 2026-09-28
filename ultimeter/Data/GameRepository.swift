//
//  GameRepository.swift
//  ultimeter
//

import Foundation

/// The editable values of the game form.
struct GameDraft {
    var date: Date = .now
    var opponentName: String = ""
    var tournamentName: String = ""
    var targetPoints: Int = 15
    var startingPosition: StartingPosition = .offense

    /// Starts a draft from a game, or an empty draft for a new game.
    init(game: Game? = nil) {
        guard let game else { return }
        date = game.date
        opponentName = game.opponent.name
        tournamentName = game.tournament?.name ?? ""
        targetPoints = game.targetPoints
        startingPosition = game.startingPosition
    }
}

/// The write side of the game aggregate: the game, the opponent,
/// and the tournament.
@MainActor
protocol GameRepository {
    func saveGame(_ draft: GameDraft, for team: Team, editing game: Game?) throws
    func delete(_ game: Game) throws
    func start(_ game: Game) throws
    func setCap(_ game: Game, to cap: Int) throws
    func end(_ game: Game, ourScore: Int, theirScore: Int) throws
}
