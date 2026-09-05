//
//  Game.swift
//  ultimeter
//

import Foundation
import SwiftData

/// The status of a game.
enum GameStatus: String, Codable, CaseIterable {
    case scheduled
    case live
    case ended

    /// The name shown in the user interface.
    var displayName: String {
        switch self {
        case .scheduled: "Scheduled"
        case .live: "Live"
        case .ended: "Ended"
        }
    }
}

/// Our side on point one.
enum StartingPosition: String, Codable {
    case offense
    case defense

    /// The name shown in the user interface.
    var displayName: String {
        switch self {
        case .offense: "Offense"
        case .defense: "Defense"
        }
    }
}

/// A single game played by a team.
@Model
final class Game {
    var date: Date
    var opponent: Opponent
    @Relationship(inverse: \Tournament.games)
    var tournament: Tournament?
    var team: Team
    var targetPoints: Int = 15
    var startingPosition: StartingPosition = StartingPosition.offense
    var status: GameStatus = GameStatus.scheduled

    /// The approved target values.
    static let allowedTargets = [13, 15, 17, 19, 21]

    init(
        date: Date,
        team: Team,
        opponent: Opponent,
        tournament: Tournament? = nil,
        targetPoints: Int = 15,
        startingPosition: StartingPosition = .offense,
        status: GameStatus = .scheduled
    ) {
        self.date = date
        self.team = team
        self.opponent = opponent
        self.tournament = tournament
        self.targetPoints = targetPoints
        self.startingPosition = startingPosition
        self.status = status
    }
}
