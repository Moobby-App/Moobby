//
//  AllNewsView.swift
//  moobby
//
//  Iteration 2: Semua Berita.
//

import SwiftUI

/// Semua Berita: every Green Line incident, newest first, with the same states as tab Berita.
///
/// Shares tab Berita's ``NewsViewModel``, so it doesn't load the list twice.
///
/// Covers AC17.
struct AllNewsView: View {
    let viewModel: NewsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                switch viewModel.state {
                case .loading:
                    ProgressView()
                        .padding(.top, 40)

                case .failed(let message):
                    ContentUnavailableView {
                        Label("Koneksi bermasalah", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Coba lagi") {
                            Task { await viewModel.load() }
                        }
                        .buttonStyle(.glass)
                    }

                case .loaded(let incidents) where incidents.isEmpty:
                    ContentUnavailableView("Belum ada informasi gangguan", systemImage: "checkmark.circle")

                case .loaded(let incidents):
                    ForEach(incidents) { incident in
                        NavigationLink(value: NewsRoute.detail(incident)) {
                            NewsCard(incident: incident)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Semua Berita")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.load() }
    }
}
