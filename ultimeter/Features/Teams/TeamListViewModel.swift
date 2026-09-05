//
//  TeamListViewModel.swift
//  ultimeter
//

import Foundation
import SwiftData

/// Errors thrown by the team list screen.
enum TeamListError: Error, LocalizedError {
    case deleteFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .deleteFailed(let underlying):
            "The team could not be deleted. \(underlying.localizedDescription)"
        }
    }
}

/// View model for `TeamListView`. Owns team deletion.
@Observable
@MainActor
final class TeamListViewModel {
    private let context: ModelContext
    var isSaving = false

    init(context: ModelContext) {
        self.context = context
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

    func deleteTeam(_ team: Team) throws {
        context.delete(team)
        do {
            try save()
        } catch {
            throw TeamListError.deleteFailed(underlying: error)
        }
    }
}
