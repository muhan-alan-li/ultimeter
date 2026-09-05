//
//  TeamListView.swift
//  ultimeter
//
//  Created by Muhan Li on 2026-08-27.
//

import SwiftUI
import SwiftData

/// The landing page. Lists all teams stored on the device.
struct TeamListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Team.name, comparator: .localizedStandard)])
    private var teams: [Team]

    @State private var viewModel: TeamListViewModel

    init(context: ModelContext) {
        _viewModel = State(initialValue: TeamListViewModel(context: context))
    }

    @State private var showingCreateForm = false
    @State private var teamToEdit: Team?
    @State private var teamToDelete: Team?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if teams.isEmpty {
                    emptyStateView
                } else {
                    teamList
                }
            }
            .navigationTitle("My Teams")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateForm = true
                    } label: {
                        Label("Add Team", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateForm) {
                TeamFormView(context: modelContext)
            }
            .sheet(item: $teamToEdit) { team in
                TeamFormView(context: modelContext, team: team)
            }
            .confirmationDialog(
                "Delete \(teamToDelete?.name ?? "this team")?",
                isPresented: Binding(
                    get: { teamToDelete != nil },
                    set: { if !$0 { teamToDelete = nil } }
                ),
                titleVisibility: .visible,
                presenting: teamToDelete
            ) { team in
                Button("Delete Team", role: .destructive) {
                    delete(team)
                }
                .disabled(viewModel.isSaving)
            }
            .alert("Delete Failed", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "The team could not be deleted. Try again.")
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Teams Yet", systemImage: "trophy")
        } description: {
            Text("Create your first team to start tracking stats.")
        } actions: {
            Button("Create Your First Team") {
                showingCreateForm = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var teamList: some View {
        List {
            ForEach(teams) { team in
                NavigationLink {
                    TeamDetailView(context: modelContext, team: team)
                } label: {
                    TeamRowView(team: team)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        teamToDelete = team
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button {
                        teamToEdit = team
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
    }

    private func delete(_ team: Team) {
        withAnimation {
            do {
                try viewModel.deleteTeam(team)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

/// A single row in the team list.
struct TeamRowView: View {
    let team: Team

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(team.name)
                .font(.headline)
            Text(team.division.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    guard let container = try? ModelContainer(
        for: Schema([Team.self, Player.self, Game.self, Opponent.self, Tournament.self, Point.self, Halftime.self]),
        configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
    ) else {
        fatalError("Preview container failed")
    }
    return TeamListView(context: container.mainContext)
        .modelContainer(container)
}
