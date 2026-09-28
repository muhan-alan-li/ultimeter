//
//  PlayerFormView.swift
//  ultimeter
//

import SwiftUI
import SwiftData

/// A form for creating a new player and adding it to a team.
struct PlayerFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var model: PlayerFormViewModel

    init(team: Team) {
        _model = State(initialValue: PlayerFormViewModel(team: team))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    TextField("Name", text: $model.draft.name)
                    Picker("Gender", selection: $model.draft.gender) {
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
                    .disabled(!model.canSave)
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

#Preview {
    let container = AppSchema.previewContainer()
    PlayerFormView(team: Team(name: "Example Team", division: .mixed))
        .environment(AppDependencies(container: container))
        .modelContainer(container)
}
