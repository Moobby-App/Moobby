//
//  TransJakartaStop.swift
//  moobby
//
//  Iteration 2: a TransJakarta stop connected to a Green Line station.
//

import CoreLocation

/// A TransJakarta stop connected to a Green Line station, shown as a chip in an affected station's
/// Detail Berita (F3).
///
/// Comes from local JSON for the prototype; the backend doesn't send stops yet (SPEC open question 10).
struct TransJakartaStop: Decodable, Identifiable, Hashable {
    /// A unique ID, such as `"tj-sdm-1"`.
    let id: String
    /// The stop's name, shown on the chip, such as `"Halte T20"`.
    let name: String
    /// The ``GreenLineStation/id`` of the station this stop belongs to, such as `"SDM"`.
    let stationId: String
    /// The stop's latitude, in degrees.
    let latitude: Double
    /// The stop's longitude, in degrees.
    let longitude: Double

    /// ``latitude`` and ``longitude`` as a coordinate, for opening Apple Maps (AC27).
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension TransJakartaStop {

    /// The stops in `stops` that belong to `station`, in their original order. Empty when there are none.
    ///
    /// Covers AC13 (stops shown) and AC14 (no stops, no chips).
    static func stops(for station: GreenLineStation, in stops: [TransJakartaStop]) -> [TransJakartaStop] {
        stops.filter { $0.stationId == station.id }
    }
}
