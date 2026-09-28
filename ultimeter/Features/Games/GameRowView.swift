//
//  GameRowView.swift
//  ultimeter
//

import SwiftUI
import SwiftData

/// A single row in the game list.
/// The view model supplies the text. The view maps the standing to a look.
struct GameRowView: View {
    let game: Game
    let model: GameListViewModel

    private var standing: GameStanding { model.standing(of: game) }

    private var icon: String {
        switch standing {
        case .live: "dot.radiowaves.left.and.right"
        case .scheduled: "calendar"
        case .win: "trophy.fill"
        case .loss: "xmark.circle.fill"
        case .tie: "equal.circle.fill"
        }
    }

    private var color: Color {
        switch standing {
        case .live: .blue
        case .scheduled: .secondary
        case .win: .green
        case .loss: .red
        case .tie: .secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(game.team.name) vs \(game.opponent.name)")
                    .font(.headline)
                Text(game.date, format: .dateTime.day().month().year())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if let score = model.scoreText(of: game) {
                    Text(score)
                        .font(.headline)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundStyle(model.isEnded(game) ? color : .primary)
                }
                Text(model.badgeLabel(of: game))
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color, in: Capsule())
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(model.accessibilityText(of: game))
    }
}

#Preview("GameRow states") {
    let container = AppSchema.previewContainer()
    let team = Team(name: "Example Team", division: .mixed)
    let opponent = Opponent(name: "Rivals")
    let model = GameListViewModel(team: team)

    func scoredPoints(won: Int, lost: Int) -> [Point] {
        var result: [Point] = []
        for index in 0 ..< (won + lost) {
            let point = Point(
                sequence: index,
                number: index + 1,
                status: .complete,
                startingPosition: .offense
            )
            let score = Event(
                sequence: 0,
                kind: .score,
                scoringTeam: index < won ? .us : .them,
                point: point
            )
            point.events.append(score)
            result.append(point)
        }
        return result
    }

    let rows = [
        Game(date: .now, team: team, opponent: opponent, status: .scheduled),
        Game(
            date: .now,
            team: team,
            opponent: opponent,
            status: .live,
            points: scoredPoints(won: 8, lost: 5)
        ),
        Game(
            date: .now,
            team: team,
            opponent: opponent,
            status: .ended,
            points: scoredPoints(won: 15, lost: 12)
        ),
        Game(
            date: .now,
            team: team,
            opponent: opponent,
            status: .ended,
            points: scoredPoints(won: 9, lost: 15)
        )
    ]

    return List {
        ForEach(rows) { game in
            GameRowView(game: game, model: model)
        }
    }
    .environment(AppDependencies(container: container))
    .modelContainer(container)
}
