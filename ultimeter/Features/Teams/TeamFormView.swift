//
//  TeamFormView.swift
//  ultimeter
//
//  Created by Muhan Li on 2026-08-27.
//

import SwiftUI
import SwiftData

/// A form for creating a new team or editing an existing team.
struct TeamFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var allTeams: [Team]

    @State private var viewModel: TeamFormViewModel

    /// The team being edited, if any. Used for the live duplicate-name hint only.
    /// The view model owns the authoritative check on save.
    let team: Team?

    init(context: ModelContext, team: Team? = nil) {
        self.team = team
        _viewModel = State(initialValue: TeamFormViewModel(context: context, team: team))
    }

    /// True when the trimmed name matches another team's name, ignoring case.
    private var isDuplicateName: Bool {
        guard !viewModel.trimmedName.isEmpty else { return false }
        return allTeams.contains { candidate in
            candidate.id != team?.id
                && candidate.name.caseInsensitiveCompare(viewModel.trimmedName) == .orderedSame
        }
    }

    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Team") {
                    TextField("Team Name", text: $viewModel.name)
                    Picker("Division", selection: $viewModel.division) {
                        ForEach(Division.allCases, id: \.self) { division in
                            Text(division.displayName).tag(division)
                        }
                    }
                    if isDuplicateName {
                        Text("A team with this name already exists.")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Team" : "New Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(viewModel.trimmedName.isEmpty || isDuplicateName || viewModel.isSaving)
                }
            }
            .alert("Save Failed", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "The team could not be saved. Try again.")
            }
        }
    }

    private func save() {
        do {
            try viewModel.saveTeam()
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        dismiss()
    }
}

#Preview("New Team") {
    guard let container = try? ModelContainer(
        for: Schema([Team.self, Player.self, Game.self, Opponent.self, Tournament.self, Point.self, Halftime.self]),
        configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
    ) else {
        fatalError("Preview container failed")
    }
    return TeamFormView(context: container.mainContext)
        .modelContainer(container)
}

#Preview("Edit Team") {
    guard let container = try? ModelContainer(
        for: Schema([Team.self, Player.self, Game.self, Opponent.self, Tournament.self, Point.self, Halftime.self]),
        configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
    ) else {
        fatalError("Preview container failed")
    }
    return TeamFormView(context: container.mainContext, team: Team(name: "Example Team", division: .mixed))
        .modelContainer(container)
}
