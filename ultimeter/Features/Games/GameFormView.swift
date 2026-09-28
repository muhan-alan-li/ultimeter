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

    @State private var model: GameFormViewModel

    init(team: Team, game: Game? = nil) {
        _model = State(initialValue: GameFormViewModel(team: team, game: game))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Game") {
                    DatePicker("Date", selection: $model.draft.date, displayedComponents: .date)
                    SuggestingPicker(
                        title: "Opponent Name",
                        text: $model.draft.opponentName,
                        values: allOpponents.map(\.name)
                    )
                }
                Section("Setup") {
                    Stepper(
                        "Target: \(model.draft.targetPoints)",
                        value: $model.draft.targetPoints,
                        in: Game.validTargetRange
                    )
                    .disabled(!model.isSetupEditable)
                    Picker("Starting Position", selection: $model.draft.startingPosition) {
                        Text("Offense").tag(StartingPosition.offense)
                        Text("Defense").tag(StartingPosition.defense)
                    }
                    .pickerStyle(.segmented)
                    .disabled(!model.isSetupEditable)
                }
                Section("Tournament") {
                    SuggestingPicker(
                        title: "Tournament (blank for standalone)",
                        text: $model.draft.tournamentName,
                        values: allTournaments.map(\.name)
                    )
                }
            }
            .navigationTitle(model.isEditing ? "Edit Game" : "New Game")
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
                    .disabled(!model.canSave)
                }
            }
            .connect(model)
            .errorAlert($model.error)
        }
    }

    private func save() {
        if model.save() {
            dismiss()
        }
    }
}

#Preview("New Game") {
    let container = AppSchema.previewContainer()
    GameFormView(team: Team(name: "Example Team", division: .mixed))
        .environment(AppDependencies(container: container))
        .modelContainer(container)
}

#Preview("Edit Game") {
    let container = AppSchema.previewContainer()
    let team = Team(name: "Example Team", division: .mixed)
    let game = Game(date: .now, team: team, opponent: Opponent(name: "Rivals"))
    return GameFormView(team: team, game: game)
        .environment(AppDependencies(container: container))
        .modelContainer(container)
}
