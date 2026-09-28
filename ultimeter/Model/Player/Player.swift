//
//  Player.swift
//  ultimeter
//

import Foundation
import SwiftData

/// The gender of a player.
enum Gender: String, Codable, CaseIterable {
    case male
    case female
    case nonBinary

    var displayName: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .nonBinary: "Non-binary"
        }
    }
}

/// A player who can belong to more than one team.
@Model
final class Player {
    var name: String
    var gender: Gender

    @Relationship(inverse: \Team.players)
    var teams: [Team] = []

    @Relationship(inverse: \Point.line)
    var points: [Point] = []

    @Relationship(inverse: \Event.player)
    var events: [Event] = []

    @Relationship(inverse: \Event.relatedPlayer)
    var relatedEvents: [Event] = []

    init(name: String, gender: Gender) {
        self.name = name
        self.gender = gender
    }
}
