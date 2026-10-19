//
//  RailSegment.swift
//  moobby
//
//  Created by Maula Izza Azizi on 19/10/26.
//

import SwiftUI

/// Half of the rail inside one timeline row, above or below its node. Flat: a solid line or round dots, nothing behind it.
///
/// It stretches to fill its row, so put the row in `.fixedSize(horizontal: false, vertical: true)`.
struct RailSegment: View {
    enum Style {
        /// No line: the top of the first row, the bottom of the last.
        case none
        case solid
        /// Round dots next to an incident marker, to show the stretch is disrupted.
        case dashed
    }

    let style: Style
    /// Which end touches the row's node: `.bottom` for the segment above it, `.top` for the one below.
    /// Dots keep ``nodeGap`` clear of that end.
    let nodeEdge: VerticalEdge
    var color: Color = .greenLine
    /// Line thickness and dot diameter: as thick as the collapsed leg's ``TimelineLine``.
    var width: CGFloat = 9

    /// Extra space between the last dot and the node's circle.
    private static let nodeGap: CGFloat = 6

    var body: some View {
        Group {
            switch style {
            case .none:
                Color.clear
            case .solid:
                Rectangle().fill(color).frame(width: width)
            case .dashed:
                Dots(size: width, spacing: width * 2)
                    .fill(color)
                    .frame(width: width)
                    .padding(nodeEdge == .top ? .top : .bottom, Self.nodeGap)
            }
        }
        .frame(maxHeight: .infinity)
        .accessibilityHidden(true)
    }

    /// Dots spread evenly over the height, half a step in from each end, so two segments meeting at a row
    /// boundary leave the same gap as anywhere else.
    private struct Dots: Shape {
        let size: CGFloat
        let spacing: CGFloat

        func path(in rect: CGRect) -> Path {
            guard rect.height >= size else { return Path() }
            let count = max(1, Int((rect.height / spacing).rounded()))
            let step = rect.height / CGFloat(count)
            return Path { path in
                for index in 0..<count {
                    let centerY = rect.minY + step * (CGFloat(index) + 0.5)
                    path.addEllipse(in: CGRect(x: rect.midX - size / 2, y: centerY - size / 2, width: size, height: size))
                }
            }
        }
    }
}

#Preview {
    HStack(spacing: 30) {
        RailSegment(style: .solid, nodeEdge: .top)
        RailSegment(style: .dashed, nodeEdge: .top)
    }
    .frame(height: 120)
}
