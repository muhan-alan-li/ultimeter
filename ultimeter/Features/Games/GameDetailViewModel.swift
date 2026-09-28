//
//  GameDetailViewModel.swift
//  ultimeter
//

import Foundation
import Observation

/// The view model of the game detail screen. Owns the score header,
/// the game controls, and the values of the two sheets.
@Observable
@MainActor
final class GameDetailViewModel: ScreenModel {
    @ObservationIgnored var dependencies: AppDependencies?
    var error: AppError?

    /// The game of this screen.
    let game: Game

    /// The final score entered on the End Game sheet.
    var endOurScore = 0
    var endTheirScore = 0

    /// The point cap entered on the Set Cap sheet.
    var newCap = 15

    init(game: Game) {
        self.game = game
        newCap = Game.validTargetRange.lowerBound
    }

    // MARK: - Display

    var title: String { "\(game.team.name) vs \(game.opponent.name)" }

    var scoreText: String { "\(game.ourScore) - \(game.theirScore)" }

    var targetText: String { "Target \(game.targetPoints)" }

    var startingText: String {
        "We started on \(game.startingPosition.displayName)"
    }

    // MARK: - Additional info

    var date: Date { game.date }

    var tournamentName: String { game.tournament?.name ?? "Standalone" }

    var teamName: String { game.team.name }

    var opponentName: String { game.opponent.name }

    var targetPoints: Int { game.targetPoints }

    var startingPositionName: String { game.startingPosition.displayName }

    var statusName: String { game.status.displayName }

    /// The hint under the final score fields.
    var endGameHint: String {
        "Keep the scores to end with the current result. "
            + "Increase them to add missing points for a new final score."
    }

    var halfText: String? {
        guard let number = game.halfPointNumber else { return nil }
        return "Half at point \(number)"
    }

    var isEnded: Bool { game.status == .ended }

    // MARK: - Controls

    /// The Start Game control shows on a game that did not start.
    var canStart: Bool { game.status == .scheduled && game.points.isEmpty }

    /// The End Game control shows on a live game.
    var canEnd: Bool { game.status == .live }

    /// The lowest cap that allows the game to continue.
    var capLowerBound: Int { GameProgress.capLowerBound(of: game) }

    /// The Set Cap control shows when a higher cap is still possible.
    var canSetCap: Bool {
        canEnd && capLowerBound <= Game.validTargetRange.upperBound
    }

    // MARK: - Intents

    /// Starts the game.
    @discardableResult
    func start() -> Bool {
        attempt { try deps.game.start(game) }
    }

    /// Prepares the End Game sheet from the current score.
    func prepareEndGame() {
        endOurScore = game.ourScore
        endTheirScore = game.theirScore
    }

    /// Ends the game with the entered final score.
    @discardableResult
    func end() -> Bool {
        attempt {
            try deps.game.end(
                game,
                ourScore: endOurScore,
                theirScore: endTheirScore
            )
        }
    }

    /// Prepares the Set Cap sheet from the current cap.
    func prepareCap() {
        newCap = min(
            max(game.targetPoints, capLowerBound),
            Game.validTargetRange.upperBound
        )
    }

    /// Saves the entered cap.
    @discardableResult
    func saveCap() -> Bool {
        attempt { try deps.game.setCap(game, to: newCap) }
    }
}
