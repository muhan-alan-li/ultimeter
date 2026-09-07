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

    @State private var viewModel: GameListViewModel

    init(context: ModelContext, team: Team) {
        self.team = team
        _viewModel = State(initialValue: GameListViewModel(context: context))
    }

    @State private var gameToEdit: Game?
    @State private var gameToDelete: Game?
    @State private var showingNewGame = false
    @State private var errorMessage: String?

    /// The team's games, newest first.
    private var games: [Game] {
        team.games.sorted { $0.date > $1.date }
    }

    /// The games that belong to a tournament, keyed by tournament.
    private var tournamentSections: [(tournament: Tournament, games: [Game])] {
        Dictionary(grouping: games) { $0.tournament }
            .compactMap { key, value in key.map { (tournament: $0, games: value) } }
            .sorted { lhs, rhs in
                lhs.tournament.name.localizedStandardCompare(rhs.tournament.name) == .orderedAscending
            }
    }

    private var standaloneGames: [Game] {
        games.filter { $0.tournament == nil }
    }

    var body: some View {
        Group {
            if team.games.isEmpty {
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
            GameFormView(context: modelContext, team: team)
        }
        .sheet(item: $gameToEdit) { game in
            GameFormView(context: modelContext, team: team, game: game)
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
        .alert("Delete Failed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "The game could not be deleted. Try again.")
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
                GameDetailView(context: modelContext, game: game)
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
            do {
                try viewModel.deleteGame(game)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

/// The icon, color, and badge label for a game row.
private struct RowStyle {
    let icon: String
    let color: Color
    let label: String
}

/// A single row in the game list.
struct GameRowView: View {
    let game: Game

    private var isLive: Bool { game.status == .live }
    private var isEnded: Bool { game.status == .ended }
    private var showScore: Bool { isLive || isEnded }

    /// Single source for the row's icon, color, and badge label.
    private var style: RowStyle {
        switch game.status {
        case .live:
            return RowStyle(icon: "dot.radiowaves.left.and.right", color: .blue, label: "Live")
        case .scheduled:
            return RowStyle(icon: "calendar", color: .secondary, label: "Scheduled")
        case .ended:
            let ourScore = game.ourScore
            let theirScore = game.theirScore
            if ourScore > theirScore {
                return RowStyle(icon: "trophy.fill", color: .green, label: "W")
            } else if ourScore < theirScore {
                return RowStyle(icon: "xmark.circle.fill", color: .red, label: "L")
            } else {
                return RowStyle(icon: "equal.circle.fill", color: .secondary, label: "T")
            }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: style.icon)
                .foregroundStyle(style.color)
                .font(.title3)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(game.team.name) vs \(game.opponent.name)")
                    .font(.headline)
                Text(game.date, format: .dateTime.day().month().year())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if showScore {
                    Text("\(game.ourScore) - \(game.theirScore)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundStyle(isEnded ? style.color : .primary)
                }
                Text(style.label)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(style.color, in: Capsule())
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let base = "\(game.team.name) versus \(game.opponent.name)"
        if isLive {
            return "\(base), live, current score \(game.ourScore) to \(game.theirScore)"
        }
        if isEnded {
            return "\(base), \(style.label), final score \(game.ourScore) to \(game.theirScore)"
        }
        return "\(base), scheduled"
    }
}

#Preview("GameRow states") {
    let team = Team(name: "Example Team", division: .mixed)
    let opponent = Opponent(name: "Rivals")
    func scoredPoints(won: Int, lost: Int) -> [Point] {
        var result: [Point] = []
        for index in 0..<(won + lost) {
            result.append(Point(
                sequence: index,
                number: index + 1,
                status: .complete,
                startingPosition: .offense,
                scoredBy: index < won ? .us : .them
            ))
        }
        return result
    }
    let rows = [
        Game(date: .now, team: team, opponent: opponent, status: .scheduled),
        Game(date: .now, team: team, opponent: opponent, status: .live, points: scoredPoints(won: 8, lost: 5)),
        Game(date: .now, team: team, opponent: opponent, status: .ended, points: scoredPoints(won: 15, lost: 12)),
        Game(date: .now, team: team, opponent: opponent, status: .ended, points: scoredPoints(won: 9, lost: 15))
    ]
    return List { ForEach(rows) { GameRowView(game: $0) } }
}

#Preview {
    guard let container = try? ModelContainer(
        for: Schema([Team.self, Player.self, Game.self, Opponent.self, Tournament.self, Point.self, Halftime.self]),
        configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
    ) else {
        fatalError("Preview container failed")
    }
    return NavigationStack {
        GameListView(context: container.mainContext, team: Team(name: "Example Team", division: .mixed))
    }
    .modelContainer(container)
}
