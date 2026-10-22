//
//  NewsView.swift
//  moobby
//
//  Iteration 2: tab Berita.
//

import SwiftUI

/// Tab Berita: the latest Green Line disruption news.
///
/// Thin: it draws ``NewsViewModel/state`` and forwards taps. Navigation uses ``NewsRoute``.
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

                if let routeTitle = viewModel.routeTitle {
                    Label("Rute \(routeTitle)", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                        .typography(.caption)
                        .foregroundStyle(.secondary)
                }

                content
            }
            .padding()
        }
        .navigationTitle("Moobby")
        .navigationDestination(for: NewsRoute.self) { route in
            switch route {
            case .allNews:
                AllNewsView(viewModel: viewModel)
            case .detail(let incident):
                NewsDetailView(incident: incident)
            }
        }
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

        case .loaded where viewModel.relevantIncidents.isEmpty:
            ContentUnavailableView(
                "Tidak ada gangguan di rute ini",
                systemImage: "checkmark.circle",
                description: Text("Lihat semua berita untuk gangguan lain di Green Line.")
            )
            allNewsButton

        case .loaded:
            ForEach(viewModel.latestIncidents) { incident in
                NavigationLink(value: NewsRoute.detail(incident)) {
                    NewsCard(incident: incident)
                }
                .buttonStyle(.plain)
            }

            allNewsButton
        }
    }

    /// Opens Semua Berita (AC17).
    private var allNewsButton: some View {
        NavigationLink(value: NewsRoute.allNews) {
            Text("Lihat semua berita")
                .typography(.button)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glass)
        .controlSize(.large)
    }
}

#Preview {
    NavigationStack {
        NewsView(viewModel: NewsViewModel(container: AppContainer(), routeSelection: RouteSelection()))
    }
}
