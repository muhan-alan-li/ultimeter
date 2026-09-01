//
//  Opponent.swift
//  ultimeter
//

import Foundation
import SwiftData

/// A team that the user does not manage in the app.
@Model
final class Opponent {
    @Attribute(.unique)
    var name: String

    init(name: String) {
        self.name = name
    }
}
