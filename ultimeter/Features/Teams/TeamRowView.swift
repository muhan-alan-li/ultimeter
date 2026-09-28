//
//  TeamRowView.swift
//  ultimeter
//

import SwiftUI

/// A single row in the team list.
struct TeamRowView: View {
    let team: Team

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(team.name)
                .font(.headline)
            Text(team.division.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
