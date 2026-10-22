//
//  TransJakartaStop+Maps.swift
//  moobby
//
//  Iteration 2: opening Apple Maps for a TransJakarta stop.
//

import MapKit

extension TransJakartaStop {

    /// Opens Apple Maps with walking directions from the user's current location to this stop.
    ///
    /// Directions go only to the stop, not along any TransJakarta route after it (SPEC Out of Scope,
    /// Decisions 3 and 4).
    ///
    /// Covers AC27.
    @MainActor
    func openWalkingDirections() {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let destination = MKMapItem(location: location, address: nil)
        destination.name = name
        destination.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
}
