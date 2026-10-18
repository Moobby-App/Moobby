//
//  MapSearchBar.swift
//  moobby
//
//  Created by Maula Izza Azizi on 17/10/26.
//

import SwiftUI

/// A Liquid Glass search field pinned above the bottom edge. It searches on Return, not as the user types.
struct MapSearchBar: View {
    /// The text being edited.
    @Binding var query: String
    /// Called when the user taps Search on the keyboard.
    let search: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField("Search places", text: $query)
                .submitLabel(.search)
                .onSubmit(search)
        }
        .padding()
        .glassEffect(.regular.interactive(), in: .capsule)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
