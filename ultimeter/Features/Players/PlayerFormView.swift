//
//  PlayerFormView.swift
//  ultimeter
//

import SwiftUI
import SwiftData

/// A form for creating a new player and adding it to a team.
struct PlayerFormView: View {
    @Environment(\.dismiss) private var dismiss
    let team: Team

    @State private var viewModel: PlayerFormViewModel

    init(context: ModelContext, team: Team) {
        self.team = team
        _viewModel = State(initialValue: PlayerFormViewModel(context: context, team: team))
    }

    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    TextField("Name", text: $viewModel.name)
                    Picker("Gender", selection: $viewModel.gender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.displayName).tag(gender)
                        }
                    }
                }
            }
            .navigationTitle("New Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        save()
                    }
                    .disabled(viewModel.trimmedName.isEmpty || viewModel.isSaving)
                }
            }
            .alert("Save Failed", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "The player could not be saved. Try again.")
            }
        }
    }

    private func save() {
        do {
            try viewModel.savePlayer()
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        dismiss()
    }
}

/// Lists players who are not on the team. Tapping one adds it to the team.
struct AddExistingPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Player.name, comparator: .localizedStandard)])
    private var allPlayers: [Player]
    let team: Team

    @State private var viewModel: AddExistingPlayerViewModel

    init(context: ModelContext, team: Team) {
        self.team = team
        _viewModel = State(initialValue: AddExistingPlayerViewModel(context: context))
    }

    @State private var errorMessage: String?

    private var availablePlayers: [Player] {
        allPlayers.filter { player in
            !player.teams.contains { $0 === team }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if availablePlayers.isEmpty {
                    ContentUnavailableView {
                        Label("No Players Available", systemImage: "person.2")
                    } description: {
                        Text("Create a new player to add to this team.")
                    }
                } else {
                    List(availablePlayers) { player in
                        Button {
                            add(player)
                        } label: {
                            HStack {
                                Text(player.name)
                                Spacer()
                                Text(player.gender.displayName)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .disabled(viewModel.isSaving)
                    }
                }
            }
            .navigationTitle("Add Existing Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Add Failed", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "The player could not be added. Try again.")
            }
        }
    }

    private func add(_ player: Player) {
        do {
            try viewModel.add(player, to: team)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        dismiss()
    }
}

#Preview("New Player") {
    let container = try! ModelContainer(
        for: Schema([Team.self, Player.self, Game.self, Opponent.self, Tournament.self]),
        configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
    )
    return PlayerFormView(context: container.mainContext, team: Team(name: "Example Team", division: .mixed))
        .modelContainer(container)
}

#Preview("Add Existing Player") {
    let container = try! ModelContainer(
        for: Schema([Team.self, Player.self, Game.self, Opponent.self, Tournament.self]),
        configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
    )
    return AddExistingPlayerView(context: container.mainContext, team: Team(name: "Example Team", division: .mixed))
        .modelContainer(container)
}
