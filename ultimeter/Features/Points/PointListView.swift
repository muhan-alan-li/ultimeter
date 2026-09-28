//
//  PointListView.swift
//  ultimeter
//

import SwiftUI
import SwiftData

/// History of points in play order with a halftime divider.
/// Shows the latest points with an option to expand the full history.
struct PointListView: View {
    @State private var model: PointListViewModel

    init(game: Game) {
        _model = State(initialValue: PointListViewModel(game: game))
    }

    var body: some View {
        if model.isEmpty {
            Text("No points yet.")
                .foregroundStyle(.secondary)
        } else {
            if model.needsExpandControl {
                expandControl
            }
            ForEach(model.entries) { entry in
                switch entry {
                case .row(let row):
                    pointRow(row)
                case .halftime:
                    halftimeLabel
                }
            }
        }
    }

    private var expandControl: some View {
        Button {
            withAnimation {
                model.toggleExpanded()
            }
        } label: {
            Label(
                model.expandLabel,
                systemImage: model.isExpanded ? "chevron.up" : "chevron.down"
            )
        }
    }

    private var halftimeLabel: some View {
        HStack {
            Image(systemName: "flag.fill")
            Text("Halftime")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.secondary)
    }

    private func pointRow(_ row: PointListViewModel.Row) -> some View {
        NavigationLink {
            PointDetailView(game: model.game, point: row.point)
        } label: {
            HStack(spacing: 12) {
                Text(row.startsOnOffense ? "O" : "D")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                if let outcome = row.outcome {
                    Text(outcome.label)
                        .font(.subheadline)
                        .foregroundStyle(row.scoredBy == .us ? .green : .red)
                        .fontWeight(.medium)
                }
                Spacer()
                Text("\(row.ourTotal) - \(row.theirTotal)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                if let badge = model.badge(for: row) {
                    Text(badge.text)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(badgeColor(badge), in: Capsule())
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(model.accessibilityText(for: row))
        }
    }

    /// The badge background of one status. The view maps a state to a look.
    private func badgeColor(_ badge: PointListViewModel.Badge) -> Color {
        switch badge {
        case .scheduled: .secondary.opacity(0.15)
        case .live: .blue.opacity(0.15)
        }
    }
}

#Preview {
    let container = AppSchema.previewContainer()
    let team = Team(name: "Example Team", division: .mixed)
    let game = Game(date: .now, team: team, opponent: Opponent(name: "Rivals"))
    return List {
        PointListView(game: game)
    }
    .environment(AppDependencies(container: container))
    .modelContainer(container)
}
