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
    let team: Team

    @State private var model: TeamDetailViewModel
    @State private var selectedTab: TeamDetailTab = .roster
    @State private var showingNewPlayer = false
    @State private var showingAddExisting = false

    init(team: Team) {
        self.team = team
        _model = State(initialValue: TeamDetailViewModel(team: team))
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
        .connect(model)
        .errorAlert($model.error)
    }

    @ViewBuilder
    private var rosterTab: some View {
        if model.roster.isEmpty {
            emptyState
        } else {
            playerList
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
            ForEach(model.roster) { player in
                HStack {
                    Text(player.name)
                    Spacer()
                    Text(player.gender.displayName)
                        .foregroundStyle(.secondary)
                }
            }
            .onDelete { offsets in
                model.remove(at: offsets)
            }
        }
    }
}

#Preview {
    let container = AppSchema.previewContainer()
    NavigationStack {
        TeamDetailView(team: Team(name: "Example Team", division: .mixed))
    }
    .environment(AppDependencies(container: container))
    .modelContainer(container)
}
