//
//  GreenLineCorridorData.swift
//  moobby
//
//  Created by Yuki Damanik on 18/10/26.
//

import Foundation
import CoreLocation

// MARK: - 1. KRL Green Line Station Model (Milestone 0B)
/// A station on the KRL Green Line (Lin Rangkasbitung), from Tanah Abang to Rangkasbitung.
///
/// ``all`` lists the stations the app shows. They draw as green markers on the map, and incidents
/// and nearby transit are measured from them. The track between them is ``GreenLineTrack``.
///
/// ```swift
/// let kebayoran = GreenLineStation.all.first { $0.id == "KBY" }
/// ```
struct GreenLineStation: Identifiable, Hashable {
    /// The station code, such as `"THB"` for Tanah Abang. Shown under the marker.
    let id: String
    /// The full name, such as `"Stasiun Tanah Abang"`.
    let name: String
    /// Position on the line, counting from Tanah Abang (1) toward Rangkasbitung.
    let sequence: Int
    /// The station's latitude, in degrees.
    let latitude: Double
    /// The station's longitude, in degrees.
    let longitude: Double

    /// ``latitude`` and ``longitude`` as a coordinate, for MapKit.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// The stations the app shows, in line order from Tanah Abang.
    ///
    /// This is a subset: the line has 19 stops, and this list has 12 of them. Positions are hand-entered
    /// and sit within about 100 m of the station.
    static let all: [GreenLineStation] = [
        GreenLineStation(id: "THB", name: "Stasiun Tanah Abang", sequence: 1, latitude: -6.1857, longitude: 106.8108),
        GreenLineStation(id: "PLM", name: "Stasiun Palmerah", sequence: 2, latitude: -6.2072, longitude: 106.7972),
        GreenLineStation(id: "KBY", name: "Stasiun Kebayoran", sequence: 3, latitude: -6.2373, longitude: 106.7825),
        GreenLineStation(id: "PDJ", name: "Stasiun Pondok Ranji", sequence: 4, latitude: -6.2764, longitude: 106.7447),
        GreenLineStation(id: "JMU", name: "Stasiun Jurangmangu", sequence: 5, latitude: -6.2891, longitude: 106.7292),
        GreenLineStation(id: "SDM", name: "Stasiun Sudimara", sequence: 6, latitude: -6.2966, longitude: 106.7126),
        GreenLineStation(id: "RU",  name: "Stasiun Rawa Buntu", sequence: 7, latitude: -6.3149, longitude: 106.6766),
        GreenLineStation(id: "SRP", name: "Stasiun Serpong", sequence: 8, latitude: -6.3204, longitude: 106.6653),
        GreenLineStation(id: "CSK", name: "Stasiun Cisauk", sequence: 9, latitude: -6.3247, longitude: 106.6414),
        GreenLineStation(id: "PRP", name: "Stasiun Parung Panjang", sequence: 10, latitude: -6.3444, longitude: 106.5694),
        GreenLineStation(id: "MJ",  name: "Stasiun Maja", sequence: 11, latitude: -6.3314, longitude: 106.3958),
        GreenLineStation(id: "RK",  name: "Stasiun Rangkasbitung", sequence: 12, latitude: -6.3524, longitude: 106.2517)
    ]
}

// MARK: - 2. News & Disruptions Along the 3 km Corridor (Milestone 1 - Scenario A)
/// A news item or service disruption near the Green Line, shown as a pin on the map.
///
/// ``MapViewModel/corridorIncidents`` keeps only the ones within 3 km of a station.
///
/// > Note: ``curatedSamples`` is hand-written sample data for the prototype, not a live news feed.
struct CorridorIncident: Identifiable, Hashable {
    /// A unique ID, such as `"inc-001"`.
    let id: String
    /// The headline, in Indonesian, as published.
    let title: String
    /// `"service_disruption"` for problems with train service itself, such as signalling faults.
    /// `"incident"` for events around the line, such as protests, flooding, or roadworks.
    let category: String // "service_disruption" or "incident"
    /// Where it happened, such as `"Simpang Velbak Kebayoran"`. Used as the pin's title.
    let locationName: String
    /// Latitude of ``locationName``, in degrees.
    let latitude: Double
    /// Longitude of ``locationName``, in degrees.
    let longitude: Double
    /// The ``GreenLineStation/id`` of the closest station.
    let nearestStationId: String
    /// The closest station's name, as shown in the card.
    let nearestStationName: String
    /// Straight-line distance to that station, in kilometers. Entered by hand, not computed from the coordinates.
    let distanceToStationKm: Double
    /// When the source published it, already formatted for display, such as `"18 Okt 2026 • 11:20 WIB"`.
    let publishedAt: String
    /// Who reported it, such as a news site or KAI Commuter.
    let sourceName: String
    /// `"verified"` when it comes from an official operator source, `"unverified"` for news and social reports.
    /// Read ``isVerified`` instead of comparing the string.
    let verificationStatus: String // "verified" or "unverified"

    /// ``latitude`` and ``longitude`` as a coordinate, for MapKit.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// True when ``verificationStatus`` is `"verified"`; the card labels it as an operational disruption.
    var isVerified: Bool {
        verificationStatus == "verified"
    }

    /// Four sample incidents along the line, for the Route Disruptions scenario. Sources are marked "Contoh Kurasi".
    static let curatedSamples: [CorridorIncident] = [
        CorridorIncident(
            id: "inc-001",
            title: "Gangguan Persinyalan di Stasiun Sudimara, Perjalanan KRL Lin Rangkasbitung Antre",
            category: "service_disruption",
            locationName: "Stasiun Sudimara",
            latitude: -6.2966,
            longitude: 106.7126,
            nearestStationId: "SDM",
            nearestStationName: "Stasiun Sudimara",
            distanceToStationKm: 0.05,
            publishedAt: "18 Okt 2026 • 11:20 WIB",
            sourceName: "Info Resmi Commuter (Contoh Kurasi)",
            verificationStatus: "verified"
        ),
        CorridorIncident(
            id: "inc-002",
            title: "Unjuk Rasa di Sekitar DPR Palmerah, Rekayasa Lalu Lintas & Penutupan Jalan",
            category: "incident",
            locationName: "Kawasan DPR/MPR Palmerah",
            latitude: -6.2104,
            longitude: 106.8001,
            nearestStationId: "PLM",
            nearestStationName: "Stasiun Palmerah",
            distanceToStationKm: 0.48,
            publishedAt: "18 Okt 2026 • 12:05 WIB",
            sourceName: "Kompas Megapolitan (Contoh Kurasi)",
            verificationStatus: "unverified"
        ),
        CorridorIncident(
            id: "inc-003",
            title: "Genangan Banjir & Pohon Tumbang di Simpang Velbak Kebayoran Akibat Hujan Deras",
            category: "incident",
            locationName: "Simpang Velbak Kebayoran",
            latitude: -6.2392,
            longitude: 106.7845,
            nearestStationId: "KBY",
            nearestStationName: "Stasiun Kebayoran",
            distanceToStationKm: 0.31,
            publishedAt: "18 Okt 2026 • 12:40 WIB",
            sourceName: "DetikNews (Contoh Kurasi)",
            verificationStatus: "unverified"
        ),
        CorridorIncident(
            id: "inc-004",
            title: "Proyek Galian Jalan Dekat Intermoda Cisauk Sebabkan Macet Akses Ojol & Angkot",
            category: "incident",
            locationName: "Kawasan Intermoda Cisauk",
            latitude: -6.3255,
            longitude: 106.6422,
            nearestStationId: "CSK",
            nearestStationName: "Stasiun Cisauk",
            distanceToStationKm: 0.13,
            publishedAt: "18 Okt 2026 • 10:15 WIB",
            sourceName: "TangerangNews (Contoh Kurasi)",
            verificationStatus: "unverified"
        )
    ]
}

// MARK: - 3. Nearby Transit Points within 3 km of the User (Milestone 1 - Scenario B)
/// A stop for another way to travel near the Green Line, such as a TransJakarta halte, an MRT station, or a feeder bus.
///
/// ``MapViewModel/nearbyTransits(from:)`` returns the ones within 3 km of the user, with
/// ``straightLineDistanceKm`` filled in, plus any Green Line stations in range.
///
/// > Note: ``catalog`` is hand-written sample data for the prototype.
struct NearbyTransitPoint: Identifiable, Hashable {
    /// A unique ID, such as `"tr-01"`. Green Line stations returned by the search use `"krl-\(station.id)"`.
    let id: String
    /// The stop's name, such as `"Halte TransJakarta Velbak"`.
    let name: String
    /// How you travel from here, shown as a label. Free text, such as `"TransJakarta"`, `"MRT Jakarta"`,
    /// `"Shuttle Bus"`, or `"KRL Green Line"`.
    let mode: String // "TransJakarta", "MRT", "BSD Link / Shuttle", "JakLingko", "KRL"
    /// The routes or corridors that stop here, such as `"Koridor 13 (Ciledug - Tendean)"`.
    let routesInfo: String
    /// The stop's latitude, in degrees.
    let latitude: Double
    /// The stop's longitude, in degrees.
    let longitude: Double
    /// Straight-line distance from the user, in kilometers. `nil` in ``catalog``; set by
    /// ``MapViewModel/nearbyTransits(from:)``. It isn't walking distance.
    var straightLineDistanceKm: Double?

    /// ``latitude`` and ``longitude`` as a coordinate, for MapKit.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Nine sample stops near Green Line stations, grouped by area, for the Nearby Modes scenario.
    static let catalog: [NearbyTransitPoint] = [
        // Around Tanah Abang & Palmerah
        NearbyTransitPoint(id: "tr-01", name: "Halte JakLingko / Explorer Tanah Abang", mode: "TransJakarta", routesInfo: "Rute 1H, 1N, 1R, 8C, 8M, 9D", latitude: -6.1862, longitude: 106.8118),
        NearbyTransitPoint(id: "tr-02", name: "Halte Stasiun Palmerah", mode: "TransJakarta", routesInfo: "Rute 1B, 1F, 8C, S41", latitude: -6.2075, longitude: 106.7976),
        // Around Kebayoran (Per research context Velbak & Corridors 8/13)
        NearbyTransitPoint(id: "tr-03", name: "Halte TransJakarta Velbak", mode: "TransJakarta", routesInfo: "Koridor 13 (Ciledug - Tendean), 13B, L13E", latitude: -6.2394, longitude: 106.7836),
        NearbyTransitPoint(id: "tr-04", name: "Halte Pasar Kebayoran Lama", mode: "TransJakarta", routesInfo: "Koridor 8 (Lebak Bulus - Pasar Baru), 8D, 8E", latitude: -6.2381, longitude: 106.7818),
        NearbyTransitPoint(id: "tr-05", name: "Stasiun MRT ASEAN", mode: "MRT Jakarta", routesInfo: "Lin Utara-Selatan (Lebak Bulus - Bundaran HI)", latitude: -6.2397, longitude: 106.7984),
        // Around Pondok Ranji, Jurangmangu & Sudimara
        NearbyTransitPoint(id: "tr-06", name: "Shelters In-Trans Bintaro XChange (Jurangmangu)", mode: "Shuttle Bus", routesInfo: "Feeder Bintaro Jaya & Royaltrans S31", latitude: -6.2869, longitude: 106.7280),
        NearbyTransitPoint(id: "tr-07", name: "Terminal Angkot & Ojol Sudimara", mode: "Angkot / Feeder", routesInfo: "Rute C09 (Ciputat - Pondok Labu) & D15", latitude: -6.2971, longitude: 106.7131),
        // Around Rawa Buntu, Serpong & Cisauk
        NearbyTransitPoint(id: "tr-08", name: "Terminal Intermoda BSD (Stasiun Cisauk)", mode: "BSD Link / Bus", routesInfo: "BSD Link Free Shuttle (The Breeze, AEON, ICE)", latitude: -6.3253, longitude: 106.6419),
        NearbyTransitPoint(id: "tr-09", name: "Halte Feeder TransJakarta BSD City", mode: "TransJakarta", routesInfo: "Rute S11 (BSD - Jelambar)", latitude: -6.3130, longitude: 106.6750)
    ]
}

