//
//  RouteConditionView.swift
//  moobby
//
//  Iteration 2: Kondisi Rute.
//

import SwiftUI

/// Kondisi Rute: the segment's header, the "N stasiun terdampak" banner and the station timeline.
///
/// Thin: it draws ``RouteConditionViewModel/state``. The Detail Berita toggle comes in Task 9; the
/// user's position marker comes with F1.
struct RouteConditionView: View {
    @State private var viewModel: RouteConditionViewModel

    init(viewModel: RouteConditionViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RouteHeader(
                    routeTitle: viewModel.routeTitle,
                    showsWarning: viewModel.affectedCount > 0
                )

                if let bannerText = viewModel.bannerText {
                    Label(bannerText, systemImage: "exclamationmark.triangle.fill")
                        .typography(.caption)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.orange.opacity(0.15), in: .capsule)
                }

                content
            }
            .padding()
        }
        .navigationTitle("Kondisi Rute")
        .navigationBarTitleDisplayMode(.inline)
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

        case .loaded(let stations):
            VStack(spacing: 0) {
                ForEach(Array(stations.enumerated()), id: \.element.id) { index, status in
                    StationRow(
                        status: status,
                        isFirst: index == 0,
                        isLast: index == stations.count - 1
                    )
                }
            }
        }
    }
}

/// The route card: "Green Line", the segment, and ⚠️ when any station is affected.
private struct RouteHeader: View {
    let routeTitle: String
    let showsWarning: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "tram.fill")
                .font(.title2)
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Green Line")
                    .bold()
                    .typography(.body)
                Text(routeTitle)
                    .typography(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if showsWarning {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .accessibilityLabel("Ada gangguan di rute ini")
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }
}

#if DEBUG
#Preview {
    let kby = GreenLineStation.fullLine.first { $0.id == "KBY" }!
    let csk = GreenLineStation.fullLine.first { $0.id == "CSK" }!
    NavigationStack {
        RouteConditionView(viewModel: RouteConditionViewModel(container: AppContainer(), departure: kby, destination: csk))
    }
}
#endif
