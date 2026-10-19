//
//  TimelineLine.swift
//  moobby
//
//  Created by Maula Izza Azizi on 19/10/26.
//

import SwiftUI

/// The vertical line between timeline nodes. Use it as a `background` so it stretches to the row's height.
struct TimelineLine: View {
    let color: Color
    var width: CGFloat = 9
    /// Draws a thin dashed line instead, for the alternatives branch.
    var dashed = false

    var body: some View {
        ZStack {
            if dashed {
                Line()
                    .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 5]))
                    .frame(width: 2)
            } else {
                Capsule().fill(color).frame(width: width)
            }
        }
        .frame(width: TimelineNode.size)
        .accessibilityHidden(true)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: CGPoint(x: rect.midX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            }
        }
    }
}

#Preview {
    HStack {
        TimelineLine(color: .greenLine)
        TimelineLine(color: .gray, dashed: true)
    }
    .frame(height: 160)
}
