//
//  AppError.swift
//  ultimeter
//

import Foundation

/// One failure of a screen action.
enum AppError: Error, LocalizedError, Equatable {
    case notLive
    case notScheduled
    case alreadyStarted
    case invalidAction
    case noActivePoint
    case multipleActivePoints
    case detachedPoint
    case lineIncomplete(current: Int, required: Int)
    case lineFull(required: Int)
    case lineLocked
    case notOnLine
    case notOnTeam
    case missingPull
    case missingPickup
    case missingScorer
    case notHolder
    case invalidTarget(Int)
    case invalidScore
    case finalScoreBelowCurrent
    case emptyName(field: String)
    case duplicateName(String)
    case saveFailed(String)
    case unexpected(String)

    var errorDescription: String? {
        switch self {
        case .notLive:
            "The game is not live. This action is not allowed."
        case .notScheduled:
            "The game is not scheduled. This action is not allowed."
        case .alreadyStarted:
            "The game already started. This action is not allowed."
        case .invalidAction:
            "This action is not allowed in the current state."
        case .noActivePoint:
            "There is no active point."
        case .multipleActivePoints:
            "There is more than one active point."
        case .detachedPoint:
            "This point does not belong to this game."
        case .lineIncomplete(let current, let required):
            "The line has \(current) of \(required) players. Add more players."
        case .lineFull(let required):
            "The line already has \(required) players."
        case .lineLocked:
            "The line is locked. Press Sub to change it."
        case .notOnLine:
            "This player is not on the line."
        case .notOnTeam:
            "This player is not on the team."
        case .missingPull:
            "This point has no puller. Select a puller."
        case .missingPickup:
            "This point has no pickup. Select who picks up."
        case .missingScorer:
            "This point has no scorer. Select a scorer."
        case .notHolder:
            "Only the holder can score."
        case .invalidTarget(let target):
            "Invalid target \(target). Choose a value from 1 to 21."
        case .invalidScore:
            "Invalid score. Scores must be zero or higher."
        case .finalScoreBelowCurrent:
            "Invalid final score. Final score cannot be below the current score."
        case .emptyName(let field):
            "\(field) cannot be empty."
        case .duplicateName(let name):
            "A record named \"\(name)\" already exists."
        case .saveFailed(let message):
            "The change could not be saved. \(message)"
        case .unexpected(let message):
            "The action failed. \(message)"
        }
    }

    /// Converts any error to one `AppError`. Passes an `AppError` through.
    static func from(_ error: any Error) -> AppError {
        if let error = error as? AppError {
            return error
        }
        return .saveFailed(error.localizedDescription)
    }
}
