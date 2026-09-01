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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allTeams: [Team]

    /// The team to edit. When nil, the form creates a new team.
    var team: Team?

    @State private var name: String
    @State private var division: Division
    @State private var saveFailed = false

    init(team: Team? = nil) {
        self.team = team
        _name = State(initialValue: team?.name ?? "")
        _division = State(initialValue: team?.division ?? .open)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// True when the trimmed name matches another team's name, ignoring case.
    private var isDuplicateName: Bool {
        guard !trimmedName.isEmpty else { return false }
        return allTeams.contains { candidate in
            candidate.id != team?.id
                && candidate.name.caseInsensitiveCompare(trimmedName) == .orderedSame
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Team") {
                    TextField("Team Name", text: $name)
                    Picker("Division", selection: $division) {
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
            .navigationTitle(team == nil ? "New Team" : "Edit Team")
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
                    .disabled(trimmedName.isEmpty || isDuplicateName)
                }
            }
            .alert("Save Failed", isPresented: $saveFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The team could not be saved. Try again.")
            }
        }
    }

    private func save() {
        if let team {
            team.name = trimmedName
            team.division = division
        } else {
            let newTeam = Team(name: trimmedName, division: division)
            modelContext.insert(newTeam)
        }
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            saveFailed = true
            return
        }
        dismiss()
    }
}

#Preview("New Team") {
    TeamFormView()
        .modelContainer(for: [Team.self, Player.self], inMemory: true)
}

#Preview("Edit Team") {
    TeamFormView(team: Team(name: "Example Team", division: .mixed))
        .modelContainer(for: [Team.self, Player.self], inMemory: true)
}
