//
//  GreenLineBadge.swift
//  moobby
//
//  Iteration 2.
//

import SwiftUI

/// The "Green Line" label under the app title. Informational only, not a button (SPEC Screens and States).
///
/// Drawn as a soft green capsule, not a filled blue button, so it doesn't look tappable (Apple HIG).
struct GreenLineBadge: View {
    var body: some View {
        Label("Green Line", systemImage: "tram.fill")
            .typography(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.green.opacity(0.15), in: .capsule)
            .foregroundStyle(.green)
    }
}
