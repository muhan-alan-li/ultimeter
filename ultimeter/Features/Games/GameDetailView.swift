//
//  GameDetailView.swift
//  ultimeter
//

import SwiftUI
import SwiftData

/// Shows the details of a single game.
struct GameDetailView: View {
    @State private var model: GameDetailViewModel
    @State private var showingEndGame = false
    @State private var showingCapSheet = false

    init(game: Game) {
        _model = State(initialValue: GameDetailViewModel(game: game))
    }

    var body: some View {
        List {
            scoreSection
            if model.canStart {
                startSection
            }
            if model.canEnd {
                endSection
            }
            infoSection
            Section("Points") {
                PointListView(game: model.game)
            }
        }
        .navigationTitle("Game")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEndGame) {
            endGameSheet
        }
        .sheet(isPresented: $showingCapSheet) {
            capSheet
        }
        .connect(model)
        .errorAlert($model.error)
    }

    private var scoreSection: some View {
        Section {
            VStack(alignment: .center, spacing: 6) {
                Text(model.title)
                    .font(.headline)
                Text(model.scoreText)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .monospacedDigit()
                Text(model.targetText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let halfText = model.halfText {
                    Text(halfText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(model.startingText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if model.isEnded {
                    Text("Game over")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }

    private var startSection: some View {
        Section {
            Button {
                model.start()
            } label: {
                Text("Start Game")
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var endSection: some View {
        Section {
            if model.canSetCap {
                Button {
                    model.prepareCap()
                    showingCapSheet = true
                } label: {
                    Text("Set Cap")
                        .frame(maxWidth: .infinity)
                }
            }
            Button(role: .destructive) {
                model.prepareEndGame()
                showingEndGame = true
            } label: {
                Text("End Game")
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var infoSection: some View {
        Section {
            DisclosureGroup("Additional Info") {
                LabeledContent("Date", value: model.date, format: .dateTime.day().month().year())
                LabeledContent("Tournament", value: model.tournamentName)
                LabeledContent("Team", value: model.teamName)
                LabeledContent("Target", value: "\(model.targetPoints)")
                LabeledContent("Starting Position", value: model.startingPositionName)
                LabeledContent("Status", value: model.statusName)
            }
        }
    }

    private var endGameSheet: some View {
        NavigationStack {
            Form {
                Section("Current Score") {
                    Text(model.scoreText)
                        .monospacedDigit()
                }
                Section("Final Score") {
                    Stepper(
                        "\(model.teamName): \(model.endOurScore)",
                        value: $model.endOurScore,
                        in: 0 ... 99
                    )
                    Stepper(
                        "\(model.opponentName): \(model.endTheirScore)",
                        value: $model.endTheirScore,
                        in: 0 ... 99
                    )
                }
                Section {
                    Text(model.endGameHint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("End Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingEndGame = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("End Game") {
                        endGame()
                    }
                }
            }
        }
    }

    private var capSheet: some View {
        NavigationStack {
            Form {
                Section("Current Score") {
                    Text(model.scoreText)
                        .monospacedDigit()
                }
                Section("Point Cap") {
                    Stepper(
                        "Point cap: \(model.newCap)",
                        value: $model.newCap,
                        in: model.capLowerBound ... Game.validTargetRange.upperBound
                    )
                }
            }
            .navigationTitle("Set Cap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCapSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCap()
                    }
                }
            }
        }
    }

    private func endGame() {
        if model.end() {
            showingEndGame = false
        }
    }

    private func saveCap() {
        if model.saveCap() {
            showingCapSheet = false
        }
    }
}

#Preview {
    let container = AppSchema.previewContainer()
    let team = Team(name: "Example Team", division: .mixed)
    let game = Game(date: .now, team: team, opponent: Opponent(name: "Rivals"))
    return NavigationStack {
        GameDetailView(game: game)
    }
    .environment(AppDependencies(container: container))
    .modelContainer(container)
}
