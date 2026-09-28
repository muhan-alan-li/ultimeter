//
//  TeamRepository.swift
//  ultimeter
//

import Foundation

/// The editable values of the team form.
struct TeamDraft {
    var name: String = ""
    var division: Division = .open

    /// Starts a draft from a team, or an empty draft for a new team.
    init(team: Team? = nil) {
        guard let team else { return }
        name = team.name
        division = team.division
    }
}

/// The editable values of the new-player form.
struct PlayerDraft {
    var name: String = ""
    var gender: Gender = .nonBinary
}

/// The write side of the team aggregate: the team and its roster.
@MainActor
protocol TeamRepository {
    func saveTeam(_ draft: TeamDraft, editing team: Team?) throws
    func delete(_ team: Team) throws
    func addPlayer(_ draft: PlayerDraft, to team: Team) throws
    func addExisting(_ player: Player, to team: Team) throws
    func remove(_ player: Player, from team: Team) throws
}
