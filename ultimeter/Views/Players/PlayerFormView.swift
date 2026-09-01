//
//  PlayerFormView.swift
//  ultimeter
//

import SwiftUI
import SwiftData

/// A form for creating a new player and adding it to a team.
struct PlayerFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let team: Team

    @State private var name: String = ""
    @State private var gender: Gender = .nonBinary
    @State private var saveFailed = false

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    TextField("Name", text: $name)
                    Picker("Gender", selection: $gender) {
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
                    .disabled(trimmedName.isEmpty)
                }
            }
            .alert("Save Failed", isPresented: $saveFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The player could not be saved. Try again.")
            }
        }
    }

    private func save() {
        let player = Player(name: trimmedName, gender: gender)
        team.players.append(player)
        do {
            try modelContext.save()
        } catch {
            team.players.removeAll { $0 === player }
            saveFailed = true
            return
        }
        dismiss()
    }
}

/// Lists players who are not on the team. Tapping one adds it to the team.
struct AddExistingPlayerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Player.name, comparator: .localizedStandard)])
    private var allPlayers: [Player]
    let team: Team

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
        }
    }

    private func add(_ player: Player) {
        team.players.append(player)
        do {
            try modelContext.save()
        } catch {
            team.players.removeAll { $0 === player }
            return
        }
        dismiss()
    }
}

#Preview("New Player") {
    PlayerFormView(team: Team(name: "Example Team", division: .mixed))
        .modelContainer(for: [Team.self, Player.self], inMemory: true)
}
