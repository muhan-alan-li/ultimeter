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

    init() {}

    @State private var showingCreateForm = false
    @State private var teamToEdit: Team?
    @State private var teamToDelete: Team?
    @State private var deleteFailed = false

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
                TeamFormView()
            }
            .sheet(item: $teamToEdit) { team in
                TeamFormView(team: team)
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
            }
            .alert("Delete Failed", isPresented: $deleteFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The team could not be deleted. Try again.")
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
                    TeamDetailView(team: team)
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
            modelContext.delete(team)
            do {
                try modelContext.save()
            } catch {
                modelContext.rollback()
                deleteFailed = true
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
    TeamListView()
        .modelContainer(for: [Team.self, Player.self], inMemory: true)
}
