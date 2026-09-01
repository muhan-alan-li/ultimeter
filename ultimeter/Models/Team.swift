//
//  Team.swift
//  ultimeter
//
//  Created by Muhan Li on 2026-08-27.
//

import Foundation
import SwiftData

/// The division in which a team plays.
enum Division: String, Codable, CaseIterable {
    case mixed
    case open
    case womens

    /// The name shown in the user interface.
    var displayName: String {
        switch self {
        case .mixed: "Mixed"
        case .open: "Open"
        case .womens: "Womens"
        }
    }
}

/// A group of ultimate frisbee players managed by the user.
@Model
final class Team {
    var name: String
    var division: Division
    var createdAt: Date
    var players: [Player] = []

    init(name: String, division: Division, createdAt: Date = Date()) {
        self.name = name
        self.division = division
        self.createdAt = createdAt
    }
}
