//
//  GameListViewModel.swift
//  ultimeter
//

import Foundation
import Observation

/// The standing of one game on a row.
enum GameStanding {
    case scheduled
    case live
    case win
    case loss
    case tie
}

/// The view model of the game list screen. Owns the sections and the row text.
@Observable
@MainActor
final class GameListViewModel: ScreenModel {
    @ObservationIgnored var dependencies: AppDependencies?
    var error: AppError?

    private let team: Team

    init(team: Team) {
        self.team = team
    }

    /// One section of the game list.
    struct Section: Identifiable {
        let id: String
        let title: String
        let games: [Game]
    }

    /// The games of the team, newest first, grouped by tournament.
    var sections: [Section] {
        let games = team.games.sorted { $0.date > $1.date }
        var sections = Dictionary(grouping: games) { $0.tournament }
            .compactMap { tournament, grouped -> Section? in
                guard let tournament else { return nil }
                return Section(id: tournament.name, title: tournament.name, games: grouped)
            }
            .sorted {
                $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
        let standalone = games.filter { $0.tournament == nil }
        if !standalone.isEmpty {
            sections.append(
                Section(id: "standalone", title: "Standalone", games: standalone)
            )
        }
        return sections
    }

    /// Whether the team has no games.
    var isEmpty: Bool { team.games.isEmpty }

    /// The standing of one game.
    func standing(of game: Game) -> GameStanding {
        switch game.status {
        case .live:
            return .live
        case .scheduled:
            return .scheduled
        case .ended:
            if game.ourScore > game.theirScore { return .win }
            if game.ourScore < game.theirScore { return .loss }
            return .tie
        }
    }

    /// The score text of one game, when the game started.
    func scoreText(of game: Game) -> String? {
        guard game.status != .scheduled else { return nil }
        return "\(game.ourScore) - \(game.theirScore)"
    }

    /// Whether one game has ended.
    func isEnded(_ game: Game) -> Bool {
        game.status == .ended
    }

    /// The badge label of one game.
    func badgeLabel(of game: Game) -> String {
        switch standing(of: game) {
        case .scheduled: return "Scheduled"
        case .live: return "Live"
        case .win: return "W"
        case .loss: return "L"
        case .tie: return "T"
        }
    }

    /// The accessibility label of one game row.
    func accessibilityText(of game: Game) -> String {
        let base = "\(game.team.name) versus \(game.opponent.name)"
        switch standing(of: game) {
        case .scheduled:
            return "\(base), scheduled"
        case .live:
            return "\(base), live, current score \(game.ourScore) to \(game.theirScore)"
        case .win:
            return "\(base), W, final score \(game.ourScore) to \(game.theirScore)"
        case .loss:
            return "\(base), L, final score \(game.ourScore) to \(game.theirScore)"
        case .tie:
            return "\(base), T, final score \(game.ourScore) to \(game.theirScore)"
        }
    }

    /// Deletes one game.
    func delete(_ game: Game) {
        attempt { try deps.game.delete(game) }
    }
}
