//
//  PointListView.swift
//  ultimeter
//

import SwiftUI
import SwiftData

/// History of points in play order with a halftime divider.
/// Shows the latest points with an option to expand the full history.
struct PointListView: View {
    @Environment(\.modelContext) private var modelContext
    let game: Game

    @State private var showAllPoints = false

    /// Number of recent points shown while collapsed.
    private let collapsedLimit = 3

    private struct RowScore {
        let point: Point
        let ourTotal: Int
        let theirTotal: Int
    }

    private var scoredRows: [RowScore] {
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
            return RowScore(point: point, ourTotal: our, theirTotal: their)
        }
    }

    private var preHalfRows: [RowScore] {
        guard let halfNumber = game.halfPointNumber else { return scoredRows }
        return scoredRows.filter { $0.point.number < halfNumber }
    }

    private var postHalfRows: [RowScore] {
        guard let halfNumber = game.halfPointNumber else { return [] }
        return scoredRows.filter { $0.point.number >= halfNumber }
    }

    /// The latest points shown while collapsed, in play order.
    private var collapsedRows: [RowScore] {
        Array(scoredRows.suffix(collapsedLimit))
    }

    private var needsExpandControl: Bool {
        scoredRows.count > collapsedLimit
    }

    /// Whether the collapsed rows span halftime and need the divider.
    private var collapsedSpansHalftime: Bool {
        guard let halfNumber = game.halfPointNumber else { return false }
        let numbers = collapsedRows.map(\.point.number)
        guard let first = numbers.min(), let last = numbers.max() else { return false }
        return first < halfNumber && last >= halfNumber
    }

    private func rowTint(for point: Point) -> Color? {
        if point.status == .active {
            return .blue.opacity(0.15)
        }
        switch point.scoredBy {
        case .us: return .green.opacity(0.15)
        case .them: return .red.opacity(0.15)
        case nil: return nil
        }
    }

    private func accessibilityText(for row: RowScore) -> String {
        let side = row.point.startingPosition == .offense ? "offense" : "defense"
        let score = "\(row.ourTotal) to \(row.theirTotal)"
        if row.point.status == .active {
            return "Point \(row.point.number), \(side), live, score \(score)"
        }
        if let scoredBy = row.point.scoredBy {
            return "Point \(row.point.number), \(side), won by \(scoredBy.teamName(in: game)), score \(score)"
        }
        return "Point \(row.point.number), \(side), no result, score \(score)"
    }

    var body: some View {
        if needsExpandControl {
            Button {
                withAnimation {
                    showAllPoints.toggle()
                }
            } label: {
                Label(
                    showAllPoints ? "Show fewer points" : "Show all \(scoredRows.count) points",
                    systemImage: showAllPoints ? "chevron.up" : "chevron.down"
                )
            }
        }
        if game.orderedPoints.isEmpty {
            Text("No points yet.")
                .foregroundStyle(.secondary)
        } else if showAllPoints || !needsExpandControl {
            if game.halftime == nil {
                ForEach(scoredRows, id: \.point.id) { row in
                    pointRow(row)
                }
            } else {
                ForEach(preHalfRows, id: \.point.id) { row in
                    pointRow(row)
                }
                halftimeLabel
                ForEach(postHalfRows, id: \.point.id) { row in
                    pointRow(row)
                }
            }
        } else if let halfNumber = game.halfPointNumber, collapsedSpansHalftime {
            ForEach(collapsedRows.filter { $0.point.number < halfNumber }, id: \.point.id) { row in
                pointRow(row)
            }
            halftimeLabel
            ForEach(collapsedRows.filter { $0.point.number >= halfNumber }, id: \.point.id) { row in
                pointRow(row)
            }
        } else {
            ForEach(collapsedRows, id: \.point.id) { row in
                pointRow(row)
            }
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

    private func pointRow(_ row: RowScore) -> some View {
        NavigationLink {
            PointDetailView(context: modelContext, game: game, point: row.point)
        } label: {
            HStack {
                Text("\(row.point.number)")
                    .font(.headline)
                    .frame(width: 28, alignment: .leading)
                Text(row.point.startingPosition == .offense ? "O" : "D")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                Spacer()
                Text("\(row.ourTotal) - \(row.theirTotal)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                if row.point.status == .active {
                    Text("Live")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.15))
                        .clipShape(.capsule)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityText(for: row))
        }
        .listRowBackground(rowTint(for: row.point))
    }
}
