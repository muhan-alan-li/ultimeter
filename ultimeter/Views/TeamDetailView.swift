//
//  TeamDetailView.swift
//  ultimeter
//

import SwiftUI
import SwiftData

/// Shows the roster of a team. Lets the user add and remove players.
struct TeamDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let team: Team

    @State private var showingNewPlayer = false
    @State private var showingAddExisting = false

    private var players: [Player] {
        team.players.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        Group {
            if team.players.isEmpty {
                emptyState
            } else {
                playerList
            }
        }
        .navigationTitle(team.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("New Player") {
                        showingNewPlayer = true
                    }
                    Button("Existing Player") {
                        showingAddExisting = true
                    }
                } label: {
                    Label("Add Player", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewPlayer) {
            PlayerFormView(team: team)
        }
        .sheet(isPresented: $showingAddExisting) {
            AddExistingPlayerView(team: team)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Players Yet", systemImage: "person.2")
        } description: {
            Text("Add players to this team to start tracking stats.")
        }
    }

    private var playerList: some View {
        List {
            ForEach(players) { player in
                HStack {
                    Text(player.name)
                    Spacer()
                    Text(player.gender.displayName)
                        .foregroundStyle(.secondary)
                }
            }
            .onDelete { indexSet in
                deletePlayers(at: indexSet)
            }
        }
    }

    private func deletePlayers(at offsets: IndexSet) {
        for offset in offsets {
            team.players.removeAll { $0 === players[offset] }
        }
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
        }
    }
}

#Preview {
    NavigationStack {
        TeamDetailView(team: Team(name: "Example Team", division: .mixed))
    }
    .modelContainer(for: [Team.self, Player.self], inMemory: true)
}
