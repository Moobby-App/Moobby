//
//  NewsView.swift
//  moobby
//
//  Iteration 2: tab Berita.
//

import SwiftUI

/// Tab Berita: the latest Green Line disruption news.
///
/// > Note: A placeholder until Task 5 adds the news list.
struct NewsView: View {
    var body: some View {
        ContentUnavailableView("Berita Perjalanan", systemImage: "newspaper")
            .navigationTitle("Berita Perjalanan")
    }
}

#Preview {
    NavigationStack {
        NewsView()
    }
}
