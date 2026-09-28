//
//  EventKind.swift
//  ultimeter
//

import Foundation

/// The kind of action recorded in a point's event log.
enum EventKind: String, Codable {
    case pull
    case pickup
    case pass
    case block
    case drop
    case turnover
    case score
    case sub
}

/// The cause recorded for a turnover event.
enum TurnoverCause: String, Codable {
    case throwaway
    case drop
    case block
    case interception
    case incompletion
    case other
}

/// The boundary recorded when a point line opens or closes for a substitution.
enum SubstitutionPhase: String, Codable {
    case started
    case completed
}

/// The result of a pull, when the tracker records its outcome.
enum PullOutcome: String, Codable {
    case caught
    case landed
    case outOfBounds
}
