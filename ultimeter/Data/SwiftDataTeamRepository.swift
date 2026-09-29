//
//  SwiftDataTeamRepository.swift
//  ultimeter
//

import Foundation
import SwiftData

/// The SwiftData implementation of the team aggregate.
@MainActor
final class SwiftDataTeamRepository: TeamRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func saveTeam(_ draft: TeamDraft, editing team: Team?) throws {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw AppError.emptyName(field: "Team name") }
        let existing = try context.fetch(FetchDescriptor<Team>())
        let isDuplicate = existing.contains { candidate in
            candidate.id != team?.id
                && candidate.name.caseInsensitiveCompare(name) == .orderedSame
        }
        guard !isDuplicate else { throw AppError.duplicateName(name) }
        try context.write {
            if let team {
                team.name = name
                team.division = draft.division
            } else {
                context.insert(Team(name: name, division: draft.division))
            }
        }
    }

    func delete(_ team: Team) throws {
        try context.write {
            context.delete(team)
        }
    }

    func addPlayers(_ draft: PlayerDraft, to team: Team) throws {
        let names = draft.names.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !names.isEmpty else { throw AppError.emptyName(field: "Player name") }
        try context.write {
            for name in names {
                let player = Player(name: name, gender: draft.gender)
                context.insert(player)
                team.players.append(player)
            }
        }
    }

    func remove(_ player: Player, from team: Team) throws {
        guard team.players.contains(where: { $0 === player }) else { return }
        try context.write {
            team.players.removeAll { $0 === player }
        }
    }
}
