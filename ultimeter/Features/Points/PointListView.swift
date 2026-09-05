//
//  PointListView.swift
//  ultimeter
//

import SwiftUI
import SwiftData

/// History of points in play order with a halftime divider.
struct PointListView: View {
    @Environment(\.modelContext) private var modelContext
    let game: Game

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

    var body: some View {
        if game.orderedPoints.isEmpty {
            Text("No points yet.")
                .foregroundStyle(.secondary)
        } else if game.halftime == nil {
            ForEach(scoredRows, id: \.point.id) { row in
                pointRow(row)
            }
        } else {
            ForEach(preHalfRows, id: \.point.id) { row in
                pointRow(row)
            }
            HStack {
                Image(systemName: "flag.fill")
                Text("Halftime")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.secondary)
            ForEach(postHalfRows, id: \.point.id) { row in
                pointRow(row)
            }
        }
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
                if row.point.status == .active {
                    Text("–")
                        .foregroundStyle(.secondary)
                } else {
                    Text(row.point.scoredBy == .us ? "Us" : "Them")
                }
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
        }
    }
}
