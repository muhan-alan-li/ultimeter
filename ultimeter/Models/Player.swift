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

    /// The name shown in the user interface.
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

    init(name: String, gender: Gender) {
        self.name = name
        self.gender = gender
    }
}
