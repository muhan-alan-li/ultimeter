//
//  GameProgress.swift
//  ultimeter
//

import Foundation

/// The rules of game progression.
enum GameProgress {
    /// The number of the next point. Starts at 1.
    static func nextPointNumber(in game: Game) -> Int {
        (highestPointNumber(in: game) ?? 0) + 1
    }

    /// The side that starts the next point.
    /// The side turns at halftime. After a score, the scoring team pulls.
    static func side(forNextPointIn game: Game) -> StartingPosition {
        guard let last = lastCompletedPoint(in: game) else {
            return game.startingPosition
        }
        switch last.scoredBy {
        case .us:
            return .defense
        case .them:
            return .offense
        case nil:
            return game.startingPosition
        }
    }

    /// The side that starts one numbered point.
    /// The first point of the second half turns the side.
    static func side(ofPoint number: Int, in game: Game) -> StartingPosition {
        if let half = game.halftime?.pointNumber, number == half {
            return flipped(game.startingPosition)
        }
        return side(forNextPointIn: game)
    }

    /// Whether a score reached the game target.
    static func reachedTarget(_ game: Game) -> Bool {
        game.ourScore >= game.targetPoints || game.theirScore >= game.targetPoints
    }

    /// Whether a score reached the halftime target for the first time.
    static func isHalftimeReached(_ game: Game) -> Bool {
        guard game.halftime == nil else { return false }
        return game.ourScore == game.halfTarget || game.theirScore == game.halfTarget
    }

    /// Half target with integer division.
    /// Uses the frozen start-of-game value so cap changes never move halftime.
    static func halfTarget(of game: Game) -> Int {
        game.halftimeTarget ?? (game.targetPoints + 1) / 2
    }

    /// The lowest point cap that allows the game to continue.
    static func capLowerBound(of game: Game) -> Int {
        max(game.ourScore, game.theirScore) + 1
    }

    /// Setup controls stay enabled before the game starts only.
    static func isSetupEditable(_ game: Game) -> Bool {
        game.status == .scheduled && game.points.isEmpty
    }

    /// The highest point number of the game.
    private static func highestPointNumber(in game: Game) -> Int? {
        game.points.map(\.number).max()
    }

    /// The last completed point by number.
    private static func lastCompletedPoint(in game: Game) -> Point? {
        game.points
            .filter { $0.status == .complete }
            .max { $0.number < $1.number }
    }

    private static func flipped(_ side: StartingPosition) -> StartingPosition {
        side == .offense ? .defense : .offense
    }
}
