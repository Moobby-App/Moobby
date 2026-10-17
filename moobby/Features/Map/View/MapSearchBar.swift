//
//  MapSearchBar.swift
//  moobby
//
//  Created by Maula Izza Azizi on 17/10/26.
//

import SwiftUI

struct MapSearchBar: View {
    @Binding var query: String
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
