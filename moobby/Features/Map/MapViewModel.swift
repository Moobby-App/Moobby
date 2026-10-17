//
//  MapViewModel.swift
//  moobby
//
//  Created by Maula Izza Azizi on 17/10/26.
//

import MapKit
import Observation

@MainActor @Observable
final class MapViewModel {
    var query = "" {
        didSet { if query.isEmpty { results = [] } }
    }
    private(set) var results: [MKMapItem] = []
    /// The place whose card is showing, e.g. the address under the user's dot.
    var selectedPlace: MKMapItem?
    var errorMessage: String?
    var isShowingError = false

    /// Searches around what's on screen; returns true when there are results to frame.
    func search(in region: MKCoordinateRegion?) async -> Bool {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let region { request.region = region }
        do {
            results = try await MKLocalSearch(request: request).start().mapItems
        } catch MKError.placemarkNotFound {
            results = []
            show("No places found for “\(query)”.")
        } catch {
            show("Search isn't available right now. Check your connection and try again.")
        }
        return !results.isEmpty
    }

    /// Looks up the address under a coordinate and opens MapKit's own place card for it.
    func showPlace(at coordinate: CLLocationCoordinate2D) async {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else { return }
        do {
            selectedPlace = try await request.mapItems.first
        } catch {
            show("Can't find the address for your location right now.")
        }
    }

    private func show(_ message: String) {
        errorMessage = message
        isShowingError = true
    }
}
