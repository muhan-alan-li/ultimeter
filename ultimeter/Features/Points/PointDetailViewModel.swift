//
//  PointDetailViewModel.swift
//  ultimeter
//

import Foundation
import Observation

/// The view model of the point detail screen.
/// Owns the point offer, the line, and every result entry action.
@Observable
@MainActor
final class PointDetailViewModel: ScreenModel {
    @ObservationIgnored var dependencies: AppDependencies?
    var error: AppError?

    let game: Game
    let point: Point

    init(game: Game, point: Point) {
        self.game = game
        self.point = point
    }

    // MARK: - Display

    /// The state of the point and the actions it offers.
    var offer: PointOffer {
        PointRules.offer(game: game, point: point)
    }

    var title: String { "Point \(point.number)" }

    /// Our team name in this game.
    var ourTeamName: String { game.team.name }

    /// The opponent name in this game.
    var opponentName: String { game.opponent.name }

    /// The start line of the summary.
    var startedOnText: String {
        "Started on \(point.startingPosition == .offense ? "offense" : "defense")"
    }

    /// The status line of the details group.
    var statusText: String { point.status.displayName }

    /// The result of the point, if the point is complete.
    var resultText: String {
        if let outcome = point.outcome { return outcome.label }
        if let scoredBy = point.scoredBy { return scoredBy.teamName(in: game) }
        return "No result yet"
    }

    /// The one-line summary under the point title.
    var summary: String {
        var parts = [point.status.displayName]
        parts.append(point.startingPosition == .offense ? "Offense start" : "Defense start")
        if point.startingPosition == .offense, point.status != .scheduled,
            let holder = point.holder {
            parts.append("Disc: \(holder.name)")
        }
        return parts.joined(separator: " · ")
    }

    /// The text of the line count.
    var lineCountText: String {
        "\(point.line.count) of \(LineRules.size) selected"
    }

    /// The puller line of the details group.
    var pullerText: String {
        if point.startingPosition == .offense { return "They pulled" }
        return point.puller?.name ?? "Not set"
    }

    /// The scorer line of the details group.
    var scorerText: String? {
        guard point.status != .scheduled else { return nil }
        if let scorer = point.scorer { return scorer.name }
        return point.scoredBy == .them ? "No scorer" : "Not set"
    }

    /// The text of a line issue.
    func text(for issue: LineIssue) -> String {
        switch issue {
        case .incomplete(let current, let required):
            return "Line has \(current) of \(required). Complete the sub to continue."
        case .rosterTooSmall(let have, let required):
            return "Roster has \(have) players. Add players to the team to reach \(required)."
        }
    }

    /// The players who are not on the line.
    func candidates(_ offer: PointOffer) -> [Player] {
        offer.roster.filter { player in
            !offer.line.contains { $0 === player }
        }
    }

    // MARK: - Line

    func toggleLine(_ player: Player) {
        attempt { try deps.point.toggleLine(player, in: point) }
    }

    func pruneLine() {
        attempt { try deps.point.pruneLine(in: point) }
    }

    func sub() {
        attempt { try deps.point.unlockLine(in: point) }
    }

    // MARK: - Pull

    func startPull() {
        attempt { try deps.point.startPull(in: point) }
    }

    func pull(_ player: Player) {
        attempt { try deps.point.pull(in: point, by: player) }
    }

    // MARK: - Disc

    func pickUp(_ player: Player) {
        attempt { try deps.point.recordPickup(in: point, by: player) }
    }

    func pass(to receiver: Player) {
        attempt { try deps.point.recordPass(in: point, to: receiver) }
    }

    func drop(to receiver: Player) {
        attempt { try deps.point.recordDrop(in: point, to: receiver) }
    }

    func block(_ player: Player) {
        attempt { try deps.point.recordBlock(in: point, by: player) }
    }

    func ourTurnover() {
        attempt { try deps.point.recordOurTurnover(in: point) }
    }

    func theirTurnover() {
        attempt { try deps.point.recordTheirTurnover(in: point) }
    }

    // MARK: - Undo

    func undoLastEvent() {
        attempt { try deps.point.undoLastEvent(in: point) }
    }

    // MARK: - Result

    /// Scores in one tap. Returns true when the screen can close.
    @discardableResult
    func score(_ player: Player) -> Bool {
        attempt { try deps.point.scoreByPlayer(player, in: point) }
    }

    /// Records the winner. Returns true when the screen can close.
    @discardableResult
    func record(_ team: ScoringTeam) -> Bool {
        attempt { try deps.point.recordScore(of: point, in: game, scoredBy: team) }
    }
}
