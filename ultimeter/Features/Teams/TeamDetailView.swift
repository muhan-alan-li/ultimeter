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

    @State private var viewModel: TeamDetailViewModel

    init(context: ModelContext, team: Team) {
        self.team = team
        _viewModel = State(initialValue: TeamDetailViewModel(context: context))
    }

    @State private var selectedTab: TeamDetailTab = .roster
    @State private var showingNewPlayer = false
    @State private var showingAddExisting = false
    @State private var errorMessage: String?

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
                GameListView(context: modelContext, team: team)
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
            PlayerFormView(context: modelContext, team: team)
        }
        .sheet(isPresented: $showingAddExisting) {
            AddExistingPlayerView(context: modelContext, team: team)
        }
        .alert("Update Failed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "The roster could not be updated. Try again.")
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
            do {
                try viewModel.removePlayer(players[offset], from: team)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Schema([Team.self, Player.self, Game.self, Opponent.self, Tournament.self]),
        configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
    )
    return NavigationStack {
        TeamDetailView(context: container.mainContext, team: Team(name: "Example Team", division: .mixed))
    }
    .modelContainer(container)
}
