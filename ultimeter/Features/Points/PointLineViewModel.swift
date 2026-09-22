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
    case lineLocked
    case saveFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notOnTeam:
            "This player is not on the team."
        case .lineFull:
            "The line already has 7 players."
        case .lineLocked:
            "The line is locked. Press Sub to change it."
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

    /// Whether the line can change. Scheduled points are open.
    /// Active points are open only after a sub.
    func isLineEditable(_ point: Point) -> Bool {
        if point.status == .scheduled { return true }
        if point.status == .active { return !point.lineLocked }
        return false
    }

    func toggle(_ player: Player, in point: Point, for game: Game) throws {
        guard isLineEditable(point) else { throw PointLineError.lineLocked }
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
        if point.status == .active, point.line.count == Self.maxLineSize {
            point.lineLocked = true
        }
        try save()
    }

    /// Drop line players who left the team. Call when opening an editable point.
    /// Active locked lines are pruned too. A removal unlocks the line for a sub.
    func pruneMissing(from point: Point, for game: Game) throws {
        if point.status == .active, point.lineLocked {
            let before = point.line.count
            point.line.removeAll { lined in
                !game.team.players.contains { $0 === lined }
            }
            guard point.line.count != before else { return }
            point.lineLocked = false
            try save()
            return
        }
        guard isLineEditable(point) else { return }
        let before = point.line.count
        point.line.removeAll { lined in
            !game.team.players.contains { $0 === lined }
        }
        guard point.line.count != before else { return }
        try save()
    }
}
