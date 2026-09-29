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
struct PlayerNameDraft: Identifiable {
    let id = UUID()
    var name = ""
}

struct PlayerDraft {
    var names: [PlayerNameDraft] = [PlayerNameDraft()]
    var gender: Gender

    init(team: Team) {
        switch team.division {
        case .open: gender = .male
        case .womens: gender = .female
        case .mixed: gender = .nonBinary
        }
    }
}

/// The write side of the team aggregate: the team and its roster.
@MainActor
protocol TeamRepository {
    func saveTeam(_ draft: TeamDraft, editing team: Team?) throws
    func delete(_ team: Team) throws
    func addPlayers(_ draft: PlayerDraft, to team: Team) throws
    func remove(_ player: Player, from team: Team) throws
}
