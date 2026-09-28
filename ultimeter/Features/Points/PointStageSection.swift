//
//  PointStageSection.swift
//  ultimeter
//

import SwiftUI

/// The live controls of one point. Each stage shows one set of controls.
/// Every guard comes from the offer. This view only renders it.
struct PointStageSection: View {
    @Environment(\.dismiss) private var dismiss

    let model: PointDetailViewModel
    let offer: PointOffer

    var body: some View {
        switch offer.stage {
        case .defense:
            defenseControls
        case .looseDisc:
            pickupControls
        case .possession:
            possessionControls
        case .scheduled:
            pullControls
        case .complete:
            resultControls
        }
    }

    // MARK: - Defense

    private var defenseControls: some View {
        Section("On Field - Defense") {
            ForEach(offer.line) { player in
                HStack {
                    Text(player.name)
                        .lineLimit(1)
                    Spacer()
                    Button("Block") {
                        model.block(player)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityLabel("\(player.name) blocks")
                }
            }
            fullWidthButton("They threw it away") {
                model.theirTurnover()
            }
            undoDropButton
            undoTurnoverButton
            opponentScoresButton
            if offer.canSub {
                subButton
            }
        }
    }

    // MARK: - Pickup

    private var pickupControls: some View {
        Section("On Field - Pickup") {
            Text("Who picks up?")
                .font(.footnote)
                .foregroundStyle(.secondary)
            ForEach(offer.line) { player in
                HStack {
                    Text(player.name)
                        .lineLimit(1)
                    Spacer()
                    Button("Pickup") {
                        model.pickUp(player)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .accessibilityLabel("\(player.name) picks up")
                }
            }
            undoBlockButton
            undoTurnoverButton
            opponentScoresButton
            if offer.canSub {
                subButton
            }
        }
    }

    // MARK: - Possession

    private var possessionControls: some View {
        Section("On Field - Score") {
            ForEach(offer.line) { player in
                HStack {
                    if offer.holder === player {
                        Image(systemName: "circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    Text(player.name)
                        .lineLimit(1)
                        .fontWeight(offer.holder === player ? .medium : .regular)
                    Spacer()
                    if offer.holder === player {
                        Text("Holder")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Holder cannot score directly")
                    } else {
                        playerActions(player)
                    }
                }
            }
            if offer.canUndoLastPass {
                Button {
                    model.undoLastPass()
                } label: {
                    Text("Undo last pass")
                        .frame(maxWidth: .infinity)
                }
                .font(.subheadline)
            }
            fullWidthButton("We turned it over") {
                model.ourTurnover()
            }
            opponentScoresButton
            if offer.canSub {
                subButton
            }
        }
    }

    private func playerActions(_ player: Player) -> some View {
        HStack {
            Button("Pass") {
                model.pass(to: player)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(offer.isSubbing)
            .accessibilityLabel("Pass to \(player.name)")
            Button("Drop") {
                model.drop(to: player)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(offer.isSubbing)
            .accessibilityLabel("\(player.name) drops")
            Button("Score") {
                score(player)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(offer.isSubbing)
            .accessibilityLabel("\(player.name) scores")
        }
    }

    // MARK: - Pull

    private var pullControls: some View {
        Section("On Field - Pull") {
            if offer.pullerRequired {
                ForEach(offer.line) { player in
                    HStack {
                        Text(player.name)
                            .lineLimit(1)
                        Spacer()
                        Button("Pull") {
                            model.pull(player)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .accessibilityLabel("\(player.name) pulls")
                    }
                }
            } else {
                Text("They pull to start this point.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                fullWidthButton("Pull") {
                    model.startPull()
                }
                .disabled(!offer.canPull)
            }
        }
    }

    // MARK: - Result

    private var resultControls: some View {
        Section("Result") {
            resultButton(
                title: model.ourTeamName,
                isChosen: offer.scoredBy == .us
            ) {
                record(.us)
            }
            resultButton(
                title: model.opponentName,
                isChosen: offer.scoredBy == .them
            ) {
                record(.them)
            }
        }
    }
}

// MARK: - Shared controls

extension PointStageSection {

    @ViewBuilder
    private var undoTurnoverButton: some View {
        if offer.canUndoTurnover {
            fullWidthButton("Undo turnover") {
                model.undoTurnover()
            }
        }
    }

    @ViewBuilder
    private var undoDropButton: some View {
        if offer.canUndoDrop {
            fullWidthButton("Undo drop") {
                model.undoDrop()
            }
        }
    }

    @ViewBuilder
    private var undoBlockButton: some View {
        if offer.canUndoBlock {
            fullWidthButton("Undo block") {
                model.undoBlock()
            }
        }
    }

    private var opponentScoresButton: some View {
        Button {
            record(.them)
        } label: {
            Text("\(model.opponentName) scores")
                .frame(maxWidth: .infinity)
        }
        .disabled(!offer.opponentCanScore)
    }

    private var subButton: some View {
        Button {
            model.sub()
        } label: {
            Text("Sub")
                .frame(maxWidth: .infinity)
        }
    }

    private func fullWidthButton(
        _ title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
        }
    }

    private func resultButton(
        title: String,
        isChosen: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if isChosen {
                    Image(systemName: "checkmark")
                }
            }
        }
    }

    // MARK: - Actions

    private func score(_ player: Player) {
        if model.score(player) {
            dismiss()
        }
    }

    private func record(_ team: ScoringTeam) {
        if model.record(team) {
            dismiss()
        }
    }
}
