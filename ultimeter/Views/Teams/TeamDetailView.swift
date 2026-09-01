//
//  TeamDetailView.swift
//  ultimeter
//

import SwiftUI
import SwiftData

/// The two tabs of the team detail view.
enum TeamDetailTab: String, CaseIterable, Identifiable {
    case roster = "Roster"
    case games = "Games"

    var id: Self { self }
}

/// Shows the roster or the game history of a team.
struct TeamDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let team: Team

    @State private var selectedTab: TeamDetailTab = .roster
    @State private var showingNewPlayer = false
    @State private var showingAddExisting = false

    private var players: [Player] {
        team.players.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selectedTab) {
                ForEach(TeamDetailTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            switch selectedTab {
            case .roster:
                rosterTab
            case .games:
                GameListView(team: team)
            }
        }
        .navigationTitle(team.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if selectedTab == .roster {
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
        }
        .sheet(isPresented: $showingNewPlayer) {
            PlayerFormView(team: team)
        }
        .sheet(isPresented: $showingAddExisting) {
            AddExistingPlayerView(team: team)
        }
    }

    @ViewBuilder
    private var rosterTab: some View {
        Group {
            if team.players.isEmpty {
                emptyState
            } else {
                playerList
            }
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
    .modelContainer(for: [Team.self, Player.self, Game.self, Opponent.self, Tournament.self], inMemory: true)
}
