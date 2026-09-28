//
//  ModelContext+Write.swift
//  ultimeter
//

import Foundation
import SwiftData

extension ModelContext {
    /// Runs one atomic change. Rolls the context back on failure.
    /// Every repository method uses this. It is the only save path.
    func write(_ body: () throws -> Void) throws {
        do {
            try transaction { try body() }
        } catch {
            rollback()
            throw AppError.from(error)
        }
    }
}
