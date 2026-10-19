//
//  IncidentMarker.swift
//  moobby
//
//  Created by Maula Izza Azizi on 19/10/26.
//

import SwiftUI

/// The red warning circle that takes a node's place on the rail where an incident is.
struct IncidentMarker: View {
    var size: CGFloat = TimelineNode.size
    var color: Color = .incidentRed

    var body: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(size < TimelineNode.size ? .caption2 : .subheadline)
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color, in: .circle)
    }
}

#Preview {
    HStack {
        IncidentMarker()
        IncidentMarker(size: 24)
        IncidentMarker(color: .orange)
    }
}
