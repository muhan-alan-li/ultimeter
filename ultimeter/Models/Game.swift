//
//  Game.swift
//  ultimeter
//

import Foundation
import SwiftData

/// A single game played by a team.
@Model
final class Game {
    var date: Date
    var opponent: Opponent
    @Relationship(inverse: \Tournament.games)
    var tournament: Tournament?
    var team: Team

    init(date: Date, team: Team, opponent: Opponent, tournament: Tournament? = nil) {
        self.date = date
        self.team = team
        self.opponent = opponent
        self.tournament = tournament
    }
}
