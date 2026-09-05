//
//  TeamFormViewModel.swift
//  ultimeter
//

import Foundation
import SwiftData

/// Errors thrown by the team form screen.
enum TeamFormError: Error, LocalizedError {
    case emptyName
    case duplicateName(String)
    case saveFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .emptyName:
            "Team name cannot be empty."
        case .duplicateName(let name):
            "A team named \"\(name)\" already exists."
        case .saveFailed(let underlying):
            "The team could not be saved. \(underlying.localizedDescription)"
        }
    }
}

/// View model for `TeamFormView`. Owns team create and update.
@Observable
@MainActor
final class TeamFormViewModel {
    private let context: ModelContext
    private let team: Team?

    var name: String
    var division: Division
    var isSaving = false

    init(context: ModelContext, team: Team? = nil) {
        self.context = context
        self.team = team
        self.name = team?.name ?? ""
        self.division = team?.division ?? .open
    }

    var isEditing: Bool { team != nil }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() throws {
        isSaving = true
        defer { isSaving = false }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    private func allTeams() throws -> [Team] {
        try context.fetch(FetchDescriptor<Team>())
    }

    func saveTeam() throws {
        guard !trimmedName.isEmpty else { throw TeamFormError.emptyName }
        let existing = try allTeams()
        let duplicate = existing.contains {
            $0.id != team?.id && $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame
        }
        guard !duplicate else { throw TeamFormError.duplicateName(trimmedName) }
        if let team {
            team.name = trimmedName
            team.division = division
        } else {
            context.insert(Team(name: trimmedName, division: division))
        }
        do {
            try save()
        } catch let error as TeamFormError {
            throw error
        } catch {
            throw TeamFormError.saveFailed(underlying: error)
        }
    }
}
