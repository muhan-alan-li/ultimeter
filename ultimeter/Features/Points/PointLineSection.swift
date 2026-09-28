//
//  PointLineSection.swift
//  ultimeter
//

import SwiftUI

/// The line of one point: who is on it, and who can join.
/// Every rule comes from the offer. This view only renders it.
struct PointLineSection: View {
    let model: PointDetailViewModel
    let offer: PointOffer

    private let lineColumns = [
        GridItem(.adaptive(minimum: 88), spacing: 8)
    ]

    var body: some View {
        Section("Line (\(model.lineCountText))") {
            if let problem = offer.lineProblem {
                Text(model.text(for: problem))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if offer.lineIsEditable {
                editableLine
            } else {
                fixedLine
            }
        }
    }

    private var editableLine: some View {
        Group {
            Text("On line")
                .font(.caption)
                .foregroundStyle(.secondary)
            if offer.line.isEmpty {
                Text("No players selected.")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: lineColumns, spacing: 8) {
                    ForEach(offer.line) { player in
                        Button {
                            model.toggleLine(player)
                        } label: {
                            lineChip(player, onLine: true)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove \(player.name) from line")
                    }
                }
            }
            Text("Players")
                .font(.caption)
                .foregroundStyle(.secondary)
            candidateGrid
        }
    }

    private var candidateGrid: some View {
        let candidates = model.candidates(offer)
        let isFull = offer.lineIsFull
        return Group {
            if candidates.isEmpty {
                Text(isFull ? "Line is full." : "No candidates available.")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: lineColumns, spacing: 8) {
                    ForEach(candidates) { player in
                        Button {
                            model.toggleLine(player)
                        } label: {
                            lineChip(player, onLine: false)
                                .foregroundStyle(isFull ? .secondary : .primary)
                        }
                        .buttonStyle(.plain)
                        .disabled(isFull)
                        .accessibilityLabel("Add \(player.name) to line")
                    }
                }
            }
        }
    }

    private var fixedLine: some View {
        Group {
            if offer.line.isEmpty {
                Text("No line recorded.")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: lineColumns, spacing: 8) {
                    ForEach(offer.line) { player in
                        lineChip(player, onLine: true)
                            .background(chipColor, in: .capsule)
                    }
                }
            }
            if offer.canSub {
                Button {
                    model.sub()
                } label: {
                    Text("Sub")
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    /// One player chip. The colors change with the line state.
    private func lineChip(_ player: Player, onLine: Bool) -> some View {
        HStack(spacing: 4) {
            Text(player.name)
                .lineLimit(1)
            if onLine, offer.lineIsEditable {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(chipColor, in: .capsule)
    }

    /// The chip background. The view maps a line state to a look.
    private var chipColor: Color {
        if offer.lineIsEditable {
            return .blue.opacity(0.15)
        }
        return offer.stage == .scheduled
            ? .secondary.opacity(0.12)
            : .blue.opacity(0.15)
    }
}
