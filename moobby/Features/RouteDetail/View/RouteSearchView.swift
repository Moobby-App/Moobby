//
//  RouteSearchView.swift
//  moobby
//
//  Created by Maula Izza Azizi on 19/10/26.
//

import SwiftUI

/// Picks a Green Line trip: the origin defaults to the station nearest the user, and the destination is searched by name.
/// Choosing a destination opens ``RouteDetailView``.
struct RouteSearchView: View {
    /// Location state, owned by ``ContentView``.
    let tracker: LocationTrackerViewModel

    @State private var query = ""
    /// The origin the user picked; `nil` follows the station nearest their location.
    @State private var pickedOriginID: String?

    private var nearest: (station: GreenLineStation, meters: Int)? {
        tracker.location.flatMap(RouteStatusLogic.nearestStation(to:))
    }

    private var origin: GreenLineStation? {
        pickedOriginID.flatMap { id in GreenLineStation.all.first { $0.id == id } } ?? nearest?.station
    }

    private var destinations: [GreenLineStation] {
        GreenLineStation.all.filter {
            $0 != origin && (query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) || $0.id.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        List {
            Section("Dari") {
                Picker("Stasiun asal", selection: $pickedOriginID) {
                    Text(nearest.map { "Terdekat: \($0.station.name)" } ?? "Pilih stasiun").tag(String?.none)
                    ForEach(GreenLineStation.all) { Text($0.name).tag(Optional($0.id)) }
                }
                if pickedOriginID == nil, let nearest {
                    Label("± \(nearest.meters) m dari lokasimu (garis lurus)", systemImage: "figure.walk")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if tracker.location == nil {
                    Label("Lokasi belum tersedia, pilih stasiun asal", systemImage: "location.slash")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Ke") {
                ForEach(destinations) { destination in
                    if let origin {
                        NavigationLink {
                            RouteDetailView(
                                origin: origin,
                                destination: destination,
                                walkMeters: pickedOriginID == nil ? nearest?.meters : nil
                            )
                        } label: {
                            Label(destination.name, systemImage: "tram.fill")
                        }
                    } else {
                        Label(destination.name, systemImage: "tram.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "Cari stasiun tujuan")
        .navigationTitle("Green Line")
        .onAppear { tracker.activate() }
        .onDisappear { tracker.deactivate() }
    }
}

#Preview {
    NavigationStack {
        RouteSearchView(tracker: LocationTrackerViewModel())
    }
}
