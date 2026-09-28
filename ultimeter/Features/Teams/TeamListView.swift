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
    @Query(sort: [SortDescriptor(\Team.name, comparator: .localizedStandard)])
    private var teams: [Team]

    @State private var model = TeamListViewModel()
    @State private var showingCreateForm = false
    @State private var teamToEdit: Team?
    @State private var teamToDelete: Team?

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
            .connect(model)
            .errorAlert($model.error)
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
            model.delete(team)
        }
    }
}

#Preview {
    let container = AppSchema.previewContainer()
    TeamListView()
        .environment(AppDependencies(container: container))
        .modelContainer(container)
}
