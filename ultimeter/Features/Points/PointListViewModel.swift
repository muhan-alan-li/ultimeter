//
//  PointListViewModel.swift
//  ultimeter
//

import Foundation
import Observation

/// The view model of the point list. Owns the running score fold,
/// the halftime split, and the collapsed view.
@Observable
@MainActor
final class PointListViewModel: ScreenModel {
    @ObservationIgnored var dependencies: AppDependencies?
    var error: AppError?

    /// Whether the full history is shown.
    var isExpanded = false

    /// The game of this screen.
    let game: Game

    /// The number of recent points shown while collapsed.
    private let collapsedLimit = 3

    init(game: Game) {
        self.game = game
    }

    /// One point with the score after it.
    struct Row: Identifiable {
        let point: Point
        let ourTotal: Int
        let theirTotal: Int
        /// The result of the point, if the point is complete.
        let outcome: PointOutcome?
        /// The team that won the point, if the point is complete.
        let scoredBy: ScoringTeam?
        /// Whether we started the point on offense.
        let startsOnOffense: Bool

        var id: Int { point.number }
    }

    /// One entry of the list. Either a point or the halftime divider.
    enum Entry: Identifiable {
        case row(Row)
        case halftime

        var id: String {
            switch self {
            case .row(let row): "row-\(row.id)"
            case .halftime: "halftime"
            }
        }
    }

    /// The status badge of one point.
    enum Badge {
        case scheduled
        case live

        var text: String {
            switch self {
            case .scheduled: "Scheduled"
            case .live: "Live"
            }
        }
    }

    /// The status badge of one point, if the point needs one.
    func badge(for row: Row) -> Badge? {
        switch row.point.status {
        case .scheduled: .scheduled
        case .active: .live
        case .complete: nil
        }
    }

    /// Whether the game has no points.
    var isEmpty: Bool { game.orderedPoints.isEmpty }

    /// Whether the collapse control is necessary.
    var needsExpandControl: Bool { rows.count > collapsedLimit }

    var expandLabel: String {
        isExpanded ? "Show fewer points" : "Show all \(rows.count) points"
    }

    /// The entries to show, with the halftime divider in place.
    var entries: [Entry] {
        let all = rows
        guard !all.isEmpty else { return [] }
        let shown = isExpanded || !needsExpandControl
            ? all
            : Array(all.suffix(collapsedLimit))
        guard let half = game.halfPointNumber else {
            return shown.map(Entry.row)
        }
        let before = shown.filter { $0.point.number < half }
        let after = shown.filter { $0.point.number >= half }
        guard !before.isEmpty, !after.isEmpty else {
            return shown.map(Entry.row)
        }
        return before.map(Entry.row) + [.halftime] + after.map(Entry.row)
    }

    /// Collapses or expands the history.
    func toggleExpanded() {
        isExpanded.toggle()
    }

    /// The accessibility label of one point row.
    func accessibilityText(for row: Row) -> String {
        let side = row.point.startingPosition == .offense ? "offense" : "defense"
        let score = "\(row.ourTotal) to \(row.theirTotal)"
        if row.point.status == .scheduled {
            return "Point \(row.point.number), \(side), scheduled, score \(score)"
        }
        if row.point.status == .active {
            return "Point \(row.point.number), \(side), live, score \(score)"
        }
        if let outcome = row.point.outcome {
            return "Point \(row.point.number), \(side), \(outcome.label), score \(score)"
        }
        return "Point \(row.point.number), \(side), no result, score \(score)"
    }

    /// Every point with the running score at that point.
    private var rows: [Row] {
        var our = 0
        var their = 0
        return game.orderedPoints.map { point in
            if point.status == .complete {
                if point.scoredBy == .us {
                    our += 1
                } else if point.scoredBy == .them {
                    their += 1
                }
            }
            return Row(
                point: point,
                ourTotal: our,
                theirTotal: their,
                outcome: point.outcome,
                scoredBy: point.scoredBy,
                startsOnOffense: point.startingPosition == .offense
            )
        }
    }
}
