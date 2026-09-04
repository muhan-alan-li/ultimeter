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
    @State private var targetPoints: Int
    @State private var startingPosition: StartingPosition
    @State private var saveFailed = false
    @State private var setupErrorMessage: String?

    init(team: Team, game: Game? = nil) {
        self.team = team
        self.game = game
        _date = State(initialValue: game?.date ?? Date())
        _opponentName = State(initialValue: game?.opponent.name ?? "")
        _tournamentName = State(initialValue: game?.tournament?.name ?? "")
        _targetPoints = State(initialValue: game?.targetPoints ?? 15)
        _startingPosition = State(initialValue: game?.startingPosition ?? .offense)
    }

    private var trimmedOpponentName: String {
        opponentName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedTournamentName: String {
        tournamentName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Setup controls stay enabled before the game starts only.
    /// Date, opponent, and tournament remain editable at any time.
    private var isSetupEditable: Bool {
        game?.status ?? .scheduled == .scheduled
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
                Section("Setup") {
                    Picker("Target", selection: $targetPoints) {
                        ForEach(Game.allowedTargets, id: \.self) { target in
                            Text("\(target)").tag(target)
                        }
                    }
                    .disabled(!isSetupEditable)
                    Picker("Starting Position", selection: $startingPosition) {
                        Text("Offense").tag(StartingPosition.offense)
                        Text("Defense").tag(StartingPosition.defense)
                    }
                    .pickerStyle(.segmented)
                    .disabled(!isSetupEditable)
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
            .alert(
                "Invalid Setup",
                isPresented: Binding(
                    get: { setupErrorMessage != nil },
                    set: { if !$0 { setupErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(setupErrorMessage ?? "Invalid setup.")
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
            if isSetupEditable {
                do {
                    try game.setTarget(targetPoints)
                } catch {
                    modelContext.rollback()
                    setupErrorMessage = error.localizedDescription
                    return
                }
                game.startingPosition = startingPosition
            }
        } else {
            let newGame = Game(
                date: date,
                team: team,
                opponent: opponent,
                tournament: tournament,
                targetPoints: targetPoints,
                startingPosition: startingPosition,
                status: .scheduled
            )
            do {
                try newGame.setTarget(targetPoints)
            } catch {
                setupErrorMessage = error.localizedDescription
                return
            }
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
