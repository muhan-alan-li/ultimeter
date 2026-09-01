//
//  GameDetailView.swift
//  ultimeter
//

import SwiftUI
import SwiftData

/// Shows the details of a single game.
struct GameDetailView: View {
    let game: Game

    var body: some View {
        List {
            Section("Game") {
                LabeledContent("Date", value: game.date, format: .dateTime.day().month().year())
                LabeledContent("Opponent", value: game.opponent.name)
                LabeledContent("Tournament", value: game.tournament?.name ?? "Standalone")
                LabeledContent("Team", value: game.team.name)
            }
        }
        .navigationTitle("Game")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        GameDetailView(game: Game(
            date: .now,
            team: Team(name: "Example Team", division: .mixed),
            opponent: Opponent(name: "Rivals")
        ))
    }
    .modelContainer(for: [Team.self, Player.self, Game.self, Opponent.self, Tournament.self], inMemory: true)
}
