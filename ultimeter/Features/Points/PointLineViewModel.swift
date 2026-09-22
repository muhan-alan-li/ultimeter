//
//  PointLineViewModel.swift
//  ultimeter
//

import Foundation
import SwiftData

/// Errors thrown by the point line selection.
enum PointLineError: Error, LocalizedError {
    case notOnTeam
    case lineFull
    case saveFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notOnTeam:
            "This player is not on the team."
        case .lineFull:
            "The line already has 7 players."
        case .saveFailed(let underlying):
            "The line could not be updated. \(underlying.localizedDescription)"
        }
    }
}

/// View model for line selection on a point. Owns the 7-player line only.
@Observable
@MainActor
final class PointLineViewModel {
    static let maxLineSize = 7

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    private func save() throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw PointLineError.saveFailed(underlying: error)
        }
    }

    /// Roster sorted by name for display and selection.
    func roster(for game: Game) -> [Player] {
        game.team.players.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    /// Line sorted by name for display.
    func sortedLine(for point: Point) -> [Player] {
        point.line.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    func isSelected(_ player: Player, in point: Point) -> Bool {
        point.line.contains { $0 === player }
    }

    func toggle(_ player: Player, in point: Point, for game: Game) throws {
        if let index = point.line.firstIndex(where: { $0 === player }) {
            point.line.remove(at: index)
            try save()
            return
        }
        guard game.team.players.contains(where: { $0 === player }) else {
            throw PointLineError.notOnTeam
        }
        guard point.line.count < Self.maxLineSize else {
            throw PointLineError.lineFull
        }
        point.line.append(player)
        try save()
    }

    /// Drop line players who left the team. Call when opening the point.
    func pruneMissing(from point: Point, for game: Game) throws {
        let before = point.line.count
        point.line.removeAll { lined in
            !game.team.players.contains { $0 === lined }
        }
        guard point.line.count != before else { return }
        try save()
    }
}
