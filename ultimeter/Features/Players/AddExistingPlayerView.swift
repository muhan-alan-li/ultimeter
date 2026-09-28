//
//  AddExistingPlayerView.swift
//  ultimeter
//

import SwiftUI
import SwiftData

/// Lists players who are not on the team. Tapping one adds it to the team.
struct AddExistingPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Player.name, comparator: .localizedStandard)])
    private var allPlayers: [Player]

    @State private var model: AddExistingPlayerViewModel

    init(team: Team) {
        _model = State(initialValue: AddExistingPlayerViewModel(team: team))
    }

    var body: some View {
        NavigationStack {
            Group {
                if availablePlayers.isEmpty {
                    emptyState
                } else {
                    playerList
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
            .connect(model)
            .errorAlert($model.error)
        }
    }

    private var availablePlayers: [Player] {
        model.available(in: allPlayers)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Players Available", systemImage: "person.2")
        } description: {
            Text("Create a new player to add to this team.")
        }
    }

    private var playerList: some View {
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
        }
    }

    private func add(_ player: Player) {
        if model.add(player) {
            dismiss()
        }
    }
}

#Preview {
    let container = AppSchema.previewContainer()
    AddExistingPlayerView(team: Team(name: "Example Team", division: .mixed))
        .environment(AppDependencies(container: container))
        .modelContainer(container)
}
