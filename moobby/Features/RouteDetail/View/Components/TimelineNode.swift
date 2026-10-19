//
//  TimelineNode.swift
//  moobby
//
//  Created by Maula Izza Azizi on 19/10/26.
//

import SwiftUI

/// A 36 pt circle on the timeline's left rail.
struct TimelineNode: View {
    enum Style {
        /// Black fill, white icon: the walk step.
        case filled
        /// White fill, dark green-gray ring: a station.
        case outlined
        /// Small white node with a colored ring: an alternative transit point.
        case alternative(Color)
    }

    let systemImage: String
    var style: Style = .outlined

    static let size: CGFloat = 36
    private static let stationRing = Color(red: 0x3E / 255, green: 0x55 / 255, blue: 0x4A / 255)

    var body: some View {
        switch style {
        case .filled:
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: Self.size, height: Self.size)
                .background(.black, in: .circle)
        case .outlined:
            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundStyle(Self.stationRing)
                .frame(width: Self.size, height: Self.size)
                .background(.white, in: .circle)
                .overlay(Circle().strokeBorder(Self.stationRing, lineWidth: 2))
        case .alternative(let color):
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(.white, in: .circle)
                .overlay(Circle().strokeBorder(color, lineWidth: 1.5))
                .frame(width: Self.size)
        }
    }
}

#Preview {
    HStack {
        TimelineNode(systemImage: "figure.walk", style: .filled)
        TimelineNode(systemImage: "tram.fill")
        TimelineNode(systemImage: "bus.fill", style: .alternative(.blue))
    }
}
