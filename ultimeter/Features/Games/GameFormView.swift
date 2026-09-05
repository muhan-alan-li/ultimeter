//
//  GameFormView.swift
//  ultimeter
//

import SwiftUI
import SwiftData

/// A form for creating a new game or editing an existing game.
struct GameFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var allTournaments: [Tournament]
    @Query private var allOpponents: [Opponent]

    @State private var viewModel: GameFormViewModel

    init(context: ModelContext, team: Team, game: Game? = nil) {
        _viewModel = State(initialValue: GameFormViewModel(context: context, team: team, game: game))
    }

    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Game") {
                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                    SuggestingPicker(
                        title: "Opponent Name",
                        text: $viewModel.opponentName,
                        values: allOpponents.map(\.name)
                    )
                }
                Section("Setup") {
                    Picker("Target", selection: $viewModel.targetPoints) {
                        ForEach(Game.allowedTargets, id: \.self) { target in
                            Text("\(target)").tag(target)
                        }
                    }
                    .disabled(!viewModel.isSetupEditable)
                    Picker("Starting Position", selection: $viewModel.startingPosition) {
                        Text("Offense").tag(StartingPosition.offense)
                        Text("Defense").tag(StartingPosition.defense)
                    }
                    .pickerStyle(.segmented)
                    .disabled(!viewModel.isSetupEditable)
                }
                Section("Tournament") {
                    SuggestingPicker(
                        title: "Tournament (blank for standalone)",
                        text: $viewModel.tournamentName,
                        values: allTournaments.map(\.name)
                    )
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Game" : "New Game")
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
                    .disabled(viewModel.trimmedOpponentName.isEmpty || viewModel.isSaving)
                }
            }
            .alert("Save Failed", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "The game could not be saved. Try again.")
            }
        }
    }

    private func save() {
        do {
            try viewModel.saveGame()
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        dismiss()
    }
}

#Preview("New Game") {
    let container = try! ModelContainer(
        for: Schema([Team.self, Player.self, Game.self, Opponent.self, Tournament.self]),
        configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
    )
    return GameFormView(context: container.mainContext, team: Team(name: "Example Team", division: .mixed))
        .modelContainer(container)
}

#Preview("Edit Game") {
    let container = try! ModelContainer(
        for: Schema([Team.self, Player.self, Game.self, Opponent.self, Tournament.self]),
        configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
    )
    let team = Team(name: "Example Team", division: .mixed)
    let game = Game(date: .now, team: team, opponent: Opponent(name: "Rivals"))
    return GameFormView(context: container.mainContext, team: team, game: game)
        .modelContainer(container)
}
