//
//  FlowLayout.swift
//  Nocturne
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var isRTL: Bool = false

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { row in
            row.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0
        }.reduce(0) { $0 + $1 + spacing } - spacing
        return CGSize(width: proposal.width ?? 0, height: max(height, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            let rowHeight = row.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0
            if isRTL {
                // Words stay in logical (reading) order for correct row-wrapping,
                // but we fill each row from the trailing edge inward so the
                // whole line reads right-to-left, matching RTL scripts.
                var x = bounds.maxX
                for index in row {
                    let size = subviews[index].sizeThatFits(.unspecified)
                    x -= size.width
                    subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                    x -= spacing
                }
            } else {
                var x = bounds.minX
                for index in row {
                    let size = subviews[index].sizeThatFits(.unspecified)
                    subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                    x += size.width + spacing
                }
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[Int]] {
        var rows: [[Int]] = [[]]
        var x: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        for (i, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                x = 0
            }
            rows[rows.count - 1].append(i)
            x += size.width + spacing
        }
        return rows
    }
}
