//
//  GameFormView.swift
//  ultimeter
//

import SwiftUI
import SwiftData

/// A form for creating a new game or editing an existing game.
struct GameFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allTournaments: [Tournament]
    @Query private var allOpponents: [Opponent]

    /// The team that plays the game.
    let team: Team
    /// The game to edit. When nil, the form creates a new game.
    var game: Game?

    @State private var date: Date
    @State private var opponentName: String
    @State private var tournamentName: String
    @State private var saveFailed = false

    init(team: Team, game: Game? = nil) {
        self.team = team
        self.game = game
        _date = State(initialValue: game?.date ?? Date())
        _opponentName = State(initialValue: game?.opponent.name ?? "")
        _tournamentName = State(initialValue: game?.tournament?.name ?? "")
    }

    private var trimmedOpponentName: String {
        opponentName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedTournamentName: String {
        tournamentName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Game") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    SuggestingPicker(
                        title: "Opponent Name",
                        text: $opponentName,
                        values: allOpponents.map(\.name)
                    )
                }
                Section("Tournament") {
                    SuggestingPicker(
                        title: "Tournament (blank for standalone)",
                        text: $tournamentName,
                        values: allTournaments.map(\.name)
                    )
                }
            }
            .navigationTitle(game == nil ? "New Game" : "Edit Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(trimmedOpponentName.isEmpty)
                }
            }
            .alert("Save Failed", isPresented: $saveFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The game could not be saved. Try again.")
            }
        }
    }

    private func findOrCreateOpponent(_ name: String) -> Opponent {
        let existing = allOpponents.first {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }
        if let existing {
            return existing
        }
        let opponent = Opponent(name: name)
        modelContext.insert(opponent)
        return opponent
    }

    /// The stored tournament that matches the name, or a new one. Nil for an empty name.
    private func findOrCreateTournament(_ name: String) -> Tournament? {
        guard !name.isEmpty else { return nil }
        let existing = allTournaments.first {
            $0.name.caseInsensitiveCompare(name) == .orderedSame
        }
        if let existing {
            return existing
        }
        let tournament = Tournament(name: name)
        modelContext.insert(tournament)
        return tournament
    }

    private func save() {
        let opponent = findOrCreateOpponent(trimmedOpponentName)
        let tournament = findOrCreateTournament(trimmedTournamentName)
        if let game {
            game.date = date
            game.opponent = opponent
            game.tournament = tournament
        } else {
            let newGame = Game(date: date, team: team, opponent: opponent, tournament: tournament)
            modelContext.insert(newGame)
            team.games.append(newGame)
        }
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            saveFailed = true
            return
        }
        dismiss()
    }
}

#Preview("New Game") {
    GameFormView(team: Team(name: "Example Team", division: .mixed))
        .modelContainer(for: [Team.self, Player.self, Game.self, Opponent.self, Tournament.self], inMemory: true)
}

#Preview("Edit Game") {
    let team = Team(name: "Example Team", division: .mixed)
    let game = Game(date: .now, team: team, opponent: Opponent(name: "Rivals"))
    return GameFormView(team: team, game: game)
        .modelContainer(for: [Team.self, Player.self, Game.self, Opponent.self, Tournament.self], inMemory: true)
}
