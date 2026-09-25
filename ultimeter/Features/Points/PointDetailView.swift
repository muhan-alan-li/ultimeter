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
    @State private var showDetails = false

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

    private var canPull: Bool {
        point.status == .scheduled
            && game.status == .live
            && point.line.count == PointLineViewModel.maxLineSize
            && (point.startingPosition == .offense || point.puller != nil)
    }

    private var canSub: Bool {
        point.status == .active && game.status == .live && point.lineLocked
    }

    private var isLineEditable: Bool {
        lineViewModel.isLineEditable(point)
    }

    private var isOngoing: Bool {
        point.status == .active && point.lineLocked && game.status == .live
    }

    private var holderOnLine: Bool {
        guard let holder = point.holder else { return false }
        return point.line.contains { $0 === holder }
    }

    private var needsPickup: Bool {
        point.holder == nil || !holderOnLine
    }

    private var canUndoTurnover: Bool {
        point.orderedStats.last?.kind == .turnover
    }

    private var canUndoDrop: Bool {
        point.orderedStats.last?.kind == .drop
    }

    private var canUndoBlock: Bool {
        point.orderedStats.last?.kind == .block
    }

    private var pointSummary: String {
        var parts = [point.status.displayName]
        parts.append(point.startingPosition == .offense ? "Offense start" : "Defense start")
        if point.startingPosition == .offense && point.status != .scheduled {
            if let holder = point.holder {
                parts.append("Disc: \(holder.name)")
            }
        }
        return parts.joined(separator: " · ")
    }

    private var canScore: Bool {
        if point.status == .complete { return true }
        if point.status == .active {
            return point.line.count == PointLineViewModel.maxLineSize
        }
        return false
    }

    private var pullerText: String {
        if point.startingPosition == .offense {
            "They pulled"
        } else if let puller = point.puller {
            puller.name
        } else {
            "Not set"
        }
    }

    private var scorerText: String? {
        if point.status == .scheduled { return nil }
        if let scorer = point.scorer {
            return scorer.name
        }
        return point.scoredBy == .them ? "No scorer" : "Not set"
    }

    private var lineIncompleteText: String? {
        guard point.status == .active else { return nil }
        guard point.line.count != PointLineViewModel.maxLineSize else { return nil }
        return "Line has \(point.line.count) of \(PointLineViewModel.maxLineSize). Complete the sub to continue."
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
                Text(pointSummary)
                    .font(.subheadline)
                    .lineLimit(2)
                DisclosureGroup("Details", isExpanded: $showDetails) {
                    LabeledContent("Status", value: point.status.displayName)
                    LabeledContent("Result", value: resultText)
                    if point.status != .scheduled {
                        LabeledContent("Puller", value: pullerText)
                    }
                    if let scorerText {
                        LabeledContent("Scorer", value: scorerText)
                    }
                    if !point.blockers.isEmpty {
                        LabeledContent(
                            "Blocks",
                            value: point.blockers.map(\.name).joined(separator: ", ")
                        )
                    }
                    if point.status != .scheduled {
                        LabeledContent("Disc", value: point.holder?.name ?? "No one")
                        LabeledContent("Passes", value: "\(point.passCount)")
                    }
                    if point.status != .scheduled && point.dropCount > 0 {
                        LabeledContent("Drops", value: "\(point.dropCount)")
                    }
                }
            }
            if !isOngoing {
                Section("Line (\(lineCountText))") {
                if let lineIncompleteText {
                    Text(lineIncompleteText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if roster.count < PointLineViewModel.maxLineSize {
                    Text("Roster has fewer than 7 players. Add players to the team.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if isLineEditable && game.status == .live {
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
                                    .background(
                                        point.status == .active
                                            ? .blue.opacity(0.15)
                                            : .secondary.opacity(0.12)
                                    )
                                    .clipShape(.capsule)
                            }
                        }
                    }
                    if canSub {
                        Button {
                            unlockForSub()
                        } label: {
                            Text("Sub")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    }
                }
            }
            if isOngoing {
                if point.phase == .defense {
                    Section("On Field - Defense") {
                        ForEach(sortedLine) { player in
                            HStack {
                                Text(player.name)
                                    .lineLimit(1)
                                Spacer()
                                Button("Block") {
                                    recordBlock(player)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .accessibilityLabel("\(player.name) blocks")
                            }
                        }
                        Button {
                            logTheirTurnover()
                        } label: {
                            Text("They threw it away")
                                .frame(maxWidth: .infinity)
                        }
                        if canUndoDrop {
                            Button {
                                undoDrop()
                            } label: {
                                Text("Undo drop")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        if canUndoTurnover {
                            Button {
                                clearTurnover()
                            } label: {
                                Text("Undo turnover")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                            Button {
                                recordScore(.them)
                            } label: {
                                Text("\(game.opponent.name) scores")
                                    .frame(maxWidth: .infinity)
                            }
                            .disabled(!canScore)
                            Button {
                                unlockForSub()
                            } label: {
                                Text("Sub")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    } else if needsPickup {
                        Section("On Field - Pickup") {
                            Text("Who picks up?")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            ForEach(sortedLine) { player in
                                HStack {
                                    Text(player.name)
                                        .lineLimit(1)
                                    Spacer()
                                    Button("Pickup") {
                                        pickup(player)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                        .accessibilityLabel("\(player.name) picks up")
                                }
                            }
                            if canUndoBlock {
                                Button {
                                    undoBlock()
                                } label: {
                                    Text("Undo block")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            if canUndoTurnover {
                                Button {
                                    clearTurnover()
                                } label: {
                                    Text("Undo turnover")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            Button {
                                recordScore(.them)
                            } label: {
                                Text("\(game.opponent.name) scores")
                                    .frame(maxWidth: .infinity)
                            }
                            .disabled(!canScore)
                            Button {
                                unlockForSub()
                            } label: {
                                Text("Sub")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    } else {
                        Section("On Field - Score") {
                            if !holderOnLine {
                                Text("Holder is off the field.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            if holderOnLine {
                            ForEach(sortedLine) { player in
                                HStack {
                                    if point.holder === player {
                                        Image(systemName: "circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                    }
                                    Text(player.name)
                                        .lineLimit(1)
                                        .fontWeight(point.holder === player ? .medium : .regular)
                                    Spacer()
                                    if point.holder === player {
                                        Button("Score") {}
                                            .buttonStyle(.borderedProminent)
                                            .controlSize(.small)
                                            .disabled(true)
                                            .accessibilityLabel("Holder cannot score directly")
                                    } else {
                                        Button("Pass") {
                                            passTo(player)
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                        .accessibilityLabel("Pass to \(player.name)")
                                        Button("Drop") {
                                            dropTo(player)
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                        .accessibilityLabel("\(player.name) drops")
                                        Button("Score") {
                                            scoreForUs(player)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .controlSize(.small)
                                        .accessibilityLabel("\(player.name) scores")
                                    }
                                }
                            }
                            if point.passCount > 0 {
                                Button {
                                    clearLastPass()
                                } label: {
                                    Text("Undo last pass")
                                        .frame(maxWidth: .infinity)
                                }
                                .font(.subheadline)
                            }
                            Button {
                                logTurnover()
                            } label: {
                                Text("We turned it over")
                                    .frame(maxWidth: .infinity)
                            }
                            }
                            Button {
                                recordScore(.them)
                            } label: {
                                Text("\(game.opponent.name) scores")
                                    .frame(maxWidth: .infinity)
                            }
                            .disabled(!canScore)
                            Button {
                                unlockForSub()
                            } label: {
                                Text("Sub")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
            }
            if point.status == .scheduled && game.status == .live {
                if point.startingPosition == .defense && isLineFull {
                    Section("On Field - Pull") {
                        ForEach(sortedLine) { player in
                            HStack {
                                Text(player.name)
                                    .lineLimit(1)
                                Spacer()
                                Button("Pull") {
                                    pullForUs(player)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .accessibilityLabel("\(player.name) pulls")
                            }
                        }
                    }
                } else {
                    Section {
                        if point.startingPosition == .offense {
                            Text("They pull to start this point.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Button {
                            startPull()
                        } label: {
                            Text("Pull")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(!canPull)
                    }
                }
            }
            if point.status == .complete {
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
                    .disabled(!canScore)
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
                    .disabled(!canScore)
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
            } else if point.status == .complete {
                try viewModel.updatePointResult(game, point: point, scoredBy: team)
            } else {
                throw PointDetailError.invalidPoint
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startPull() {
        do {
            try viewModel.startPull(game, point: point)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func pullForUs(_ player: Player) {
        do {
            try viewModel.pullForUs(game, point: point, player: player)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func pickup(_ player: Player) {
        do {
            try viewModel.recordPickup(game, point: point, player: player)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func passTo(_ player: Player) {
        do {
            try viewModel.recordPass(game, point: point, receiver: player)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func dropTo(_ player: Player) {
        do {
            try viewModel.recordDrop(game, point: point, receiver: player)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func undoDrop() {
        do {
            try viewModel.clearDrop(game, point: point)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func clearLastPass() {
        do {
            try viewModel.clearLastPass(game, point: point)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func logTurnover() {
        do {
            try viewModel.logOurTurnover(game, point: point)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func clearTurnover() {
        do {
            try viewModel.clearTurnover(game, point: point)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func scoreForUs(_ player: Player) {
        do {
            try viewModel.scoreForUs(game, point: point, player: player)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func recordBlock(_ player: Player) {
        do {
            try viewModel.recordBlock(game, point: point, player: player)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func undoBlock() {
        do {
            try viewModel.clearLastBlock(game, point: point)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func logTheirTurnover() {
        do {
            try viewModel.logTheirTurnover(game, point: point)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func unlockForSub() {
        do {
            try viewModel.unlockForSub(game, point: point)
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
