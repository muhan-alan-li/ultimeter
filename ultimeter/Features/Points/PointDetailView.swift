//
//  PointDetailView.swift
//  ultimeter
//

import SwiftUI
import SwiftData

/// Detail for one point. Records or edits its result.
struct PointDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let game: Game
    let point: Point

    @State private var viewModel: PointDetailViewModel
    @State private var errorMessage: String?

    init(context: ModelContext, game: Game, point: Point) {
        self.game = game
        self.point = point
        _viewModel = State(initialValue: PointDetailViewModel(context: context))
    }

    private var resultText: String {
        if let outcome = point.outcome {
            outcome.label
        } else if let scoredBy = point.scoredBy {
            scoredBy.teamName(in: game)
        } else {
            "No result yet"
        }
    }

    var body: some View {
        List {
            Section("Point") {
                if point.status == .complete, let outcome = point.outcome {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(outcome.label)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(point.scoredBy == .us ? .green : .red)
                            Text("Started on \(point.startingPosition == .offense ? "offense" : "defense")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                LabeledContent("Result", value: resultText)
            }
            Section("Result") {
                Button {
                    recordScore(.us)
                } label: {
                    HStack {
                        Text("\(game.team.name) scores")
                        Spacer()
                        if point.scoredBy == .us {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                Button {
                    recordScore(.them)
                } label: {
                    HStack {
                        Text("\(game.opponent.name) scores")
                        Spacer()
                        if point.scoredBy == .them {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
        .navigationTitle("Point \(point.number)")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Update Failed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "The point could not be updated. Try again.")
        }
    }

    private func recordScore(_ team: ScoringTeam) {
        do {
            if point.status == .active {
                try viewModel.completeActivePoint(game, scoredBy: team)
            } else {
                try viewModel.updatePointResult(game, point: point, scoredBy: team)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
