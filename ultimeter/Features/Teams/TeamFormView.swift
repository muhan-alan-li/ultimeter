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

    @State private var model: TeamFormViewModel

    init(team: Team? = nil) {
        _model = State(initialValue: TeamFormViewModel(team: team))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Team") {
                    TextField("Team Name", text: $model.draft.name)
                    Picker("Division", selection: $model.draft.division) {
                        ForEach(Division.allCases, id: \.self) { division in
                            Text(division.displayName).tag(division)
                        }
                    }
                    if model.hasDuplicate(in: allTeams) {
                        Text("A team with this name already exists.")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(model.isEditing ? "Edit Team" : "New Team")
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
                    .disabled(!model.canSave(in: allTeams))
                }
            }
            .connect(model)
            .errorAlert($model.error)
        }
    }

    private func save() {
        if model.save() {
            dismiss()
        }
    }
}

#Preview("New Team") {
    let container = AppSchema.previewContainer()
    TeamFormView()
        .environment(AppDependencies(container: container))
        .modelContainer(container)
}

#Preview("Edit Team") {
    let container = AppSchema.previewContainer()
    TeamFormView(team: Team(name: "Example Team", division: .mixed))
        .environment(AppDependencies(container: container))
        .modelContainer(container)
}
