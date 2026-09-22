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
    @State private var lineViewModel: PointLineViewModel
    @State private var errorMessage: String?

    init(context: ModelContext, game: Game, point: Point) {
        self.game = game
        self.point = point
        _viewModel = State(initialValue: PointDetailViewModel(context: context))
        _lineViewModel = State(initialValue: PointLineViewModel(context: context))
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

    private var roster: [Player] {
        lineViewModel.roster(for: game)
    }

    private var sortedLine: [Player] {
        lineViewModel.sortedLine(for: point)
    }

    private var lineCountText: String {
        "\(point.line.count) of \(PointLineViewModel.maxLineSize) selected"
    }

    private let lineColumns = [
        GridItem(.adaptive(minimum: 88), spacing: 8)
    ]

    private var candidates: [Player] {
        roster.filter { player in
            !lineViewModel.isSelected(player, in: point)
        }
    }

    private var isLineFull: Bool {
        point.line.count >= PointLineViewModel.maxLineSize
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
            Section("Line (\(lineCountText))") {
                if roster.count < PointLineViewModel.maxLineSize {
                    Text("Roster has fewer than 7 players. Add players to the team.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if point.status == .active {
                    Text("On line")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if sortedLine.isEmpty {
                        Text("No players selected.")
                            .foregroundStyle(.secondary)
                    } else {
                        LazyVGrid(columns: lineColumns, spacing: 8) {
                            ForEach(sortedLine) { player in
                                Button {
                                    toggleLinePlayer(player)
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(player.name)
                                            .lineLimit(1)
                                        Image(systemName: "xmark")
                                            .font(.caption2)
                                    }
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(.blue.opacity(0.15))
                                    .foregroundStyle(.primary)
                                    .clipShape(.capsule)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Remove \(player.name) from line")
                            }
                        }
                    }
                    Text("Players")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if candidates.isEmpty {
                        Text(isLineFull ? "Line is full." : "No candidates available.")
                            .foregroundStyle(.secondary)
                    } else {
                        LazyVGrid(columns: lineColumns, spacing: 8) {
                            ForEach(candidates) { player in
                                Button {
                                    toggleLinePlayer(player)
                                } label: {
                                    Text(player.name)
                                        .lineLimit(1)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(.secondary.opacity(0.12))
                                        .foregroundStyle(isLineFull ? .secondary : .primary)
                                        .clipShape(.capsule)
                                }
                                .buttonStyle(.plain)
                                .disabled(isLineFull)
                                .accessibilityLabel("Add \(player.name) to line")
                            }
                        }
                    }
                } else {
                    if sortedLine.isEmpty {
                        Text("No line recorded.")
                            .foregroundStyle(.secondary)
                    } else {
                        LazyVGrid(columns: lineColumns, spacing: 8) {
                            ForEach(sortedLine) { player in
                                Text(player.name)
                                    .lineLimit(1)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(.secondary.opacity(0.12))
                                    .clipShape(.capsule)
                            }
                        }
                    }
                }
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
        .onAppear {
            pruneLine()
        }
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

    private func toggleLinePlayer(_ player: Player) {
        do {
            try lineViewModel.toggle(player, in: point, for: game)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func pruneLine() {
        do {
            try lineViewModel.pruneMissing(from: point, for: game)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
