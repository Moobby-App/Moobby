//
//  NewsView.swift
//  moobby
//
//  Iteration 2: tab Berita.
//

import SwiftUI

/// Tab Berita: the latest Green Line disruption news.
///
/// Thin: it draws ``NewsViewModel/state`` and forwards taps. "Lihat semua berita" and the Detail Berita
/// page come in Task 6.
struct NewsView: View {
    @State private var viewModel: NewsViewModel

    init(viewModel: NewsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GreenLineBadge()

                HStack(alignment: .firstTextBaseline) {
                    Text("Berita Perjalanan")
                        .typography(.title)
                    Spacer()
                    if case .loaded = viewModel.state {
                        Text(viewModel.countLabel)
                            .typography(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                content
            }
            .padding()
        }
        .navigationTitle("Moobby")
        .task { await viewModel.loadIfNeeded() }
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
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

        case .loaded:
            ForEach(viewModel.latestIncidents) { incident in
                NewsCard(incident: incident)
            }
        }
    }
}

/// The "Green Line" label under the app title. Informational only, not a button (SPEC Screens and States).
///
/// Drawn as a soft green capsule, not a filled blue button, so it doesn't look tappable (Apple HIG).
private struct GreenLineBadge: View {
    var body: some View {
        Label("Green Line", systemImage: "tram.fill")
            .typography(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.green.opacity(0.15), in: .capsule)
            .foregroundStyle(.green)
    }
}

#Preview {
    NavigationStack {
        NewsView(viewModel: NewsViewModel(container: AppContainer()))
    }
}
