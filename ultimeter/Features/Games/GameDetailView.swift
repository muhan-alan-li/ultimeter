//
//  GameDetailView.swift
//  ultimeter
//

import SwiftUI
import SwiftData

/// Shows the details of a single game.
struct GameDetailView: View {
    let game: Game

    @State private var viewModel: GameDetailViewModel

    init(context: ModelContext, game: Game) {
        self.game = game
        _viewModel = State(initialValue: GameDetailViewModel(context: context))
    }

    @State private var errorMessage: String?
    @State private var showingEndGame = false
    @State private var endOurScore = 0
    @State private var endTheirScore = 0

    private var showStartControl: Bool {
        game.status == .scheduled && game.points.isEmpty
    }

    private var showEndControl: Bool {
        game.status == .live
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .center, spacing: 6) {
                    Text("\(game.team.name) vs \(game.opponent.name)")
                        .font(.headline)
                    Text("\(game.ourScore) - \(game.theirScore)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .monospacedDigit()
                    Text("Target \(game.targetPoints)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let halfNumber = game.halfPointNumber {
                        Text("Half at point \(halfNumber)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text("We started on \(game.startingPosition.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if game.status == .ended {
                        Text("Game over")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            if showStartControl {
                Section {
                    Button {
                        startGame()
                    } label: {
                        Text("Start Game")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            if showEndControl {
                Section {
                    Button(role: .destructive) {
                        endOurScore = game.ourScore
                        endTheirScore = game.theirScore
                        showingEndGame = true
                    } label: {
                        Text("End Game")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            Section {
                DisclosureGroup("Additional Info") {
                    LabeledContent("Date", value: game.date, format: .dateTime.day().month().year())
                    LabeledContent("Tournament", value: game.tournament?.name ?? "Standalone")
                    LabeledContent("Team", value: game.team.name)
                    LabeledContent("Target", value: "\(game.targetPoints)")
                    LabeledContent("Starting Position", value: game.startingPosition.displayName)
                    LabeledContent("Status", value: game.status.displayName)
                }
            }
            Section("Points") {
                PointListView(game: game)
            }
        }
        .navigationTitle("Game")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEndGame) {
            NavigationStack {
                Form {
                    Section("Current Score") {
                        Text("\(game.ourScore) - \(game.theirScore)")
                            .monospacedDigit()
                    }
                    Section("Final Score") {
                        Stepper("\(game.team.name): \(endOurScore)", value: $endOurScore, in: 0 ... 99)
                        Stepper("\(game.opponent.name): \(endTheirScore)", value: $endTheirScore, in: 0 ... 99)
                    }
                    Section {
                        Text("Keep the scores to end with the current result. Change them to rebuild points for a new final score.")
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
        .alert("Update Failed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "The game could not be updated. Try again.")
        }
    }

    private func startGame() {
        do {
            try viewModel.startGame(game)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func endGame() {
        do {
            try viewModel.endGame(game, ourScore: endOurScore, theirScore: endTheirScore)
            showingEndGame = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    guard let container = try? ModelContainer(
        for: Schema([Team.self, Player.self, Game.self, Opponent.self, Tournament.self, Point.self, Halftime.self]),
        configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
    ) else {
        fatalError("Preview container failed")
    }
    return NavigationStack {
        GameDetailView(context: container.mainContext, game: Game(
            date: .now,
            team: Team(name: "Example Team", division: .mixed),
            opponent: Opponent(name: "Rivals")
        ))
    }
    .modelContainer(container)
}
