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
            Section {
                VStack(alignment: .center, spacing: 6) {
                    Text("\(game.team.name) vs \(game.opponent.name)")
                        .font(.headline)
                    // Scores derive from completed points in plan-points.md.
                    // No points exist yet, so show 0 - 0.
                    Text("0 - 0")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .monospacedDigit()
                    Text("We started on \(game.startingPosition.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            Section {
                DisclosureGroup("Additional Info") {
                    LabeledContent("Date", value: game.date, format: .dateTime.day().month().year())
                    LabeledContent("Tournament", value: game.tournament?.name ?? "Standalone")
                    LabeledContent("Team", value: game.team.name)
                    LabeledContent("Target", value: "\(game.targetPoints)")
                    LabeledContent("Starting Position", value: game.startingPosition.displayName)
                    LabeledContent("Status", value: game.status.displayName)
                }
            }
            Section("Event Log") {
                Text("No events yet.")
                    .foregroundStyle(.secondary)
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
