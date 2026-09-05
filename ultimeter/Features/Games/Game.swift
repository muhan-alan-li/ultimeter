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
    @Relationship(deleteRule: .cascade, inverse: \Point.game)
    var points: [Point] = []
    @Relationship(deleteRule: .cascade, inverse: \Halftime.game)
    var halftime: Halftime?
    var nextSequence: Int = 0

    /// The approved target values.
    static let allowedTargets = [13, 15, 17, 19, 21]

    init(
        date: Date,
        team: Team,
        opponent: Opponent,
        tournament: Tournament? = nil,
        targetPoints: Int = 15,
        startingPosition: StartingPosition = .offense,
        status: GameStatus = .scheduled,
        points: [Point] = [],
        halftime: Halftime? = nil,
        nextSequence: Int = 0
    ) {
        self.date = date
        self.team = team
        self.opponent = opponent
        self.tournament = tournament
        self.targetPoints = targetPoints
        self.startingPosition = startingPosition
        self.status = status
        self.points = points
        self.halftime = halftime
        self.nextSequence = nextSequence
    }

    /// Count of completed points won by our team.
    var ourScore: Int {
        points.filter { $0.status == .complete && $0.scoredBy == .us }.count
    }

    /// Count of completed points won by the other team.
    var theirScore: Int {
        points.filter { $0.status == .complete && $0.scoredBy == .them }.count
    }

    /// Points sorted by insertion order.
    var orderedPoints: [Point] {
        points.sorted { $0.sequence < $1.sequence }
    }

    /// The single active point, if one exists.
    var currentPoint: Point? {
        let active = points.filter { $0.status == .active }
        guard active.count == 1 else { return nil }
        return active[0]
    }

    /// The first point number of the second half, if halftime exists.
    var halfPointNumber: Int? {
        halftime?.pointNumber
    }

    /// Half target with integer division.
    var halfTarget: Int {
        (targetPoints + 1) / 2
    }
}
