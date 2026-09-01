//
//  GameListView.swift
//  ultimeter
//

import SwiftUI
import SwiftData

/// Lists the games of a team. Lets the user add, edit, and delete games.
struct GameListView: View {
    @Environment(\.modelContext) private var modelContext
    let team: Team

    @State private var gameToEdit: Game?
    @State private var gameToDelete: Game?
    @State private var showingNewGame = false
    @State private var deleteFailed = false

    /// The team's games, newest first.
    private var games: [Game] {
        team.games.sorted { $0.date > $1.date }
    }

    /// The games that belong to a tournament, keyed by tournament.
    private var tournamentSections: [(tournament: Tournament, games: [Game])] {
        let grouped = Dictionary(grouping: games) { game in
            game.tournament
        }
        return grouped
            .filter { $0.key != nil }
            .map { (tournament: $0.key!, games: $0.value) }
            .sorted { lhs, rhs in
                lhs.tournament.name.localizedStandardCompare(rhs.tournament.name) == .orderedAscending
            }
    }

    private var standaloneGames: [Game] {
        games.filter { $0.tournament == nil }
    }

    var body: some View {
        Group {
            if games.isEmpty {
                emptyState
            } else {
                gameList
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewGame = true
                } label: {
                    Label("Add Game", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewGame) {
            GameFormView(team: team)
        }
        .sheet(item: $gameToEdit) { game in
            GameFormView(team: team, game: game)
        }
        .confirmationDialog(
            "Delete this game?",
            isPresented: Binding(
                get: { gameToDelete != nil },
                set: { if !$0 { gameToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Game", role: .destructive) {
                if let game = gameToDelete {
                    delete(game)
                }
            }
        }
        .alert("Delete Failed", isPresented: $deleteFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The game could not be deleted. Try again.")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Games Yet", systemImage: "sport.disc")
        } description: {
            Text("Add a game to start tracking this team's history.")
        }
    }

    private var gameList: some View {
        List {
            ForEach(tournamentSections, id: \.tournament.id) { section in
                Section(section.tournament.name) {
                    gameRows(section.games)
                }
            }
            if !standaloneGames.isEmpty {
                Section("Standalone") {
                    gameRows(standaloneGames)
                }
            }
        }
    }

    private func gameRows(_ games: [Game]) -> some View {
        ForEach(games) { game in
            NavigationLink {
                GameDetailView(game: game)
            } label: {
                GameRowView(game: game)
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    gameToDelete = game
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                Button {
                    gameToEdit = game
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
            }
        }
    }

    private func delete(_ game: Game) {
        withAnimation {
            modelContext.delete(game)
            do {
                try modelContext.save()
            } catch {
                modelContext.rollback()
                deleteFailed = true
            }
        }
    }
}

/// A single row in the game list.
struct GameRowView: View {
    let game: Game

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("vs \(game.opponent.name)")
                .font(.headline)
            Text(game.date, format: .dateTime.day().month().year())
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        GameListView(team: Team(name: "Example Team", division: .mixed))
    }
    .modelContainer(for: [Team.self, Player.self, Game.self, Opponent.self, Tournament.self], inMemory: true)
}
