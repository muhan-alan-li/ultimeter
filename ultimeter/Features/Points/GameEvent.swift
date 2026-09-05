//
//  GameEvent.swift
//  ultimeter
//

import Foundation

/// The kind of game event stored on a game.
enum GameEventKind: String, Codable, CaseIterable {
    case point
    case halftime
}

/// Shared parent for game event models.
/// SwiftData does not support model inheritance,
/// so each event type is its own model class.
protocol GameEvent: AnyObject {
    var kind: GameEventKind { get }
    var sequence: Int { get set }
    var game: Game? { get set }
}
