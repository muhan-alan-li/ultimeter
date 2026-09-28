//
//  GameListView.swift
//  ultimeter
//

import SwiftUI
import SwiftData

/// Lists the games of a team. Lets the user add, edit, and delete games.
struct GameListView: View {
    let team: Team

    @State private var model: GameListViewModel
    @State private var gameToEdit: Game?
    @State private var gameToDelete: Game?
    @State private var showingNewGame = false

    init(team: Team) {
        self.team = team
        _model = State(initialValue: GameListViewModel(team: team))
    }

    var body: some View {
        Group {
            if model.isEmpty {
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
        .connect(model)
        .errorAlert($model.error)
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
            ForEach(model.sections) { section in
                Section(section.title) {
                    gameRows(section.games)
                }
            }
        }
    }

    private func gameRows(_ games: [Game]) -> some View {
        ForEach(games) { game in
            NavigationLink {
                GameDetailView(game: game)
            } label: {
                GameRowView(game: game, model: model)
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
            model.delete(game)
        }
    }
}

#Preview {
    let container = AppSchema.previewContainer()
    NavigationStack {
        GameListView(team: Team(name: "Example Team", division: .mixed))
    }
    .environment(AppDependencies(container: container))
    .modelContainer(container)
}
