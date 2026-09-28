//
//  PointDetailView.swift
//  ultimeter
//

import SwiftUI
import SwiftData

/// Detail for one point. Records or edits its result.
/// The view model owns every rule. This view only renders the offer.
struct PointDetailView: View {
    @State private var model: PointDetailViewModel
    @State private var showDetails = false

    init(game: Game, point: Point) {
        _model = State(initialValue: PointDetailViewModel(game: game, point: point))
    }

    var body: some View {
        let offer = model.offer
        List {
            summarySection(offer)
            if !offer.isOngoing || offer.lineIsEditable {
                PointLineSection(model: model, offer: offer)
            }
            PointStageSection(model: model, offer: offer)
        }
        .navigationTitle(model.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            model.pruneLine()
        }
        .connect(model)
        .errorAlert($model.error)
    }

    private func summarySection(_ offer: PointOffer) -> some View {
        Section("Point") {
            if let outcome = offer.outcome {
                VStack(alignment: .leading, spacing: 2) {
                    Text(outcome.label)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(offer.scoredBy == .us ? .green : .red)
                    Text(model.startedOnText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(model.summary)
                .font(.subheadline)
                .lineLimit(2)
            DisclosureGroup("Details", isExpanded: $showDetails) {
                LabeledContent("Status", value: model.statusText)
                LabeledContent("Result", value: model.resultText)
                if offer.hasStarted {
                    LabeledContent("Puller", value: model.pullerText)
                }
                if let scorerText = model.scorerText {
                    LabeledContent("Scorer", value: scorerText)
                }
                if !offer.blockers.isEmpty {
                    LabeledContent(
                        "Blocks",
                        value: offer.blockers.map(\.name).joined(separator: ", ")
                    )
                }
                if offer.hasStarted {
                    LabeledContent("Disc", value: offer.holder?.name ?? "No one")
                    LabeledContent("Passes", value: "\(offer.passCount)")
                }
                if offer.hasStarted, offer.dropCount > 0 {
                    LabeledContent("Drops", value: "\(offer.dropCount)")
                }
            }
        }
    }
}

#Preview {
    let container = AppSchema.previewContainer()
    let team = Team(name: "Example Team", division: .mixed)
    let game = Game(date: .now, team: team, opponent: Opponent(name: "Rivals"))
    let point = Point(
        sequence: 0,
        number: 1,
        status: .scheduled,
        startingPosition: .offense,
        game: game
    )
    return NavigationStack {
        PointDetailView(game: game, point: point)
    }
    .environment(AppDependencies(container: container))
    .modelContainer(container)
}
