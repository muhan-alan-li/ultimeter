//
//  PointDetailView.swift
//  ultimeter
//

import SwiftUI
import SwiftData

/// Detail for one point. Records or edits its result.
struct PointDetailView: View {
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
        switch point.scoredBy {
        case .us: "Us"
        case .them: "Them"
        case nil: "No result yet"
        }
    }

    var body: some View {
        List {
            Section("Point") {
                LabeledContent("Number", value: "\(point.number)")
                LabeledContent(
                    "Side",
                    value: point.startingPosition == .offense ? "Offense" : "Defense"
                )
                LabeledContent(
                    "Status",
                    value: point.status == .active ? "Active" : "Complete"
                )
                LabeledContent("Result", value: resultText)
            }
            Section("Result") {
                Button {
                    recordScore(.us)
                } label: {
                    HStack {
                        Text("We Score")
                        Spacer()
                        if point.scoredBy == .us {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .disabled(viewModel.isSaving)
                Button {
                    recordScore(.them)
                } label: {
                    HStack {
                        Text("They Score")
                        Spacer()
                        if point.scoredBy == .them {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .disabled(viewModel.isSaving)
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
