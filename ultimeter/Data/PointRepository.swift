//
//  PointRepository.swift
//  ultimeter
//

import Foundation

/// The write side of the point aggregate: the line, the disc,
/// every event of a point, and the point result.
@MainActor
protocol PointRepository {
    func toggleLine(_ player: Player, in point: Point) throws
    func pruneLine(in point: Point) throws
    func unlockLine(in point: Point) throws
    func startPull(in point: Point) throws
    func pull(in point: Point, by player: Player) throws
    func recordPickup(in point: Point, by player: Player) throws
    func recordPass(in point: Point, to receiver: Player) throws
    func recordDrop(in point: Point, to receiver: Player) throws
    func recordBlock(in point: Point, by player: Player) throws
    func recordOurTurnover(in point: Point) throws
    func recordTheirTurnover(in point: Point) throws
    func undoLastEvent(in point: Point) throws
    func scoreByPlayer(_ player: Player, in point: Point) throws
    func recordScore(of point: Point, in game: Game, scoredBy: ScoringTeam) throws
}
