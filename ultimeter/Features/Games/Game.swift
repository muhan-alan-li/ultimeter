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
    var team: Team
    var opponent: Opponent
    
    @Relationship(inverse: \Tournament.games)
    var tournament: Tournament?
    
    var targetPoints: Int = 15
    var startingPosition: StartingPosition = StartingPosition.offense
    var status: GameStatus = GameStatus.scheduled

    /// Score that triggers halftime. Frozen at game start so cap changes never move it.
    var halftimeTarget: Int?
    
    @Relationship(deleteRule: .cascade, inverse: \Point.game)
    var points: [Point] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Halftime.game)
    var halftime: Halftime?
    
    var nextSequence: Int = 0

    static let validTargetRange = 1 ... 21

    init(
        date: Date,
        team: Team,
        opponent: Opponent,
        tournament: Tournament? = nil,
        targetPoints: Int = 15,
        startingPosition: StartingPosition = .offense,
        status: GameStatus = .scheduled,
        halftimeTarget: Int? = nil,
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
        self.halftimeTarget = halftimeTarget
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

    /// The single open point (scheduled or active), if one exists.
    var currentPoint: Point? {
        let open = points.filter { $0.status != .complete }
        guard open.count == 1 else { return nil }
        return open[0]
    }

    /// The first point number of the second half, if halftime exists.
    var halfPointNumber: Int? {
        halftime?.pointNumber
    }

    /// Half target with integer division.
    /// Uses the frozen start-of-game value so cap changes never move halftime.
    var halfTarget: Int {
        halftimeTarget ?? (targetPoints + 1) / 2
    }

    /// Build the next point and advance the sequence counter.
    /// Caller inserts the result into the context and appends it to `points`.
    func makePoint(number: Int, side: StartingPosition, status: PointStatus) -> Point {
        let point = Point(
            sequence: nextSequence,
            number: number,
            status: status,
            startingPosition: side,
            game: self
        )
        nextSequence += 1
        return point
    }

    /// Build the halftime marker and advance the sequence counter.
    /// Caller inserts the result into the context and assigns it to `halftime`.
    func makeHalftime(pointNumber: Int) -> Halftime {
        let half = Halftime(
            sequence: nextSequence,
            pointNumber: pointNumber,
            game: self
        )
        nextSequence += 1
        return half
    }
}
