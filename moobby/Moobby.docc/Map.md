# Map

Show the user's position and heading, explain when location isn't available, and search for places.

## Overview

The Map tab is built from two view models and a handful of small views:

| Piece | Role |
|---|---|
| ``LocationTrackerViewModel`` | Owns Core Location: permission (``Access``), position, heading, and the route. |
| ``MapView`` | The screen. Draws the dot, route, and markers, and frames the camera. |
| ``MapViewModel`` | MapKit lookups: place search, and the address behind the user's dot. |
| ``LocationStatusView`` | Explains, with a ``LocationBanner``, why the dot isn't on the map. |
| ``LocationIndicator`` | The blue dot and heading ``Cone``. |
| ``MapControls``, ``MapSearchBar`` | The traffic and recenter buttons, and the search field. |
| ``GreenLineStation``, ``GreenLineTrack`` | The KRL Green Line's stations and track. See <doc:Map#KRL-Green-Line-Corridor>. |

![Core Location feeds LocationTrackerViewModel, which MapView observes. MapView sends searches and dot taps to MapViewModel, which asks MapKit and returns markers and the place card.](map-flow)

Dashed boxes are Apple frameworks. Solid blue arrows carry data back to the screen, and dashed arrows are calls the screen makes. ``LocationTrackerViewModel`` is the only type that talks to Core Location, and ``MapViewModel`` is the only one that talks to MapKit's search services.

## Location Permission

The app asks for **When In Use** access, the first time the map appears. iOS shows the prompt only if `NSLocationWhenInUseUsageDescription` is in Info.plist. This project sets it in `project.yml`, and it needs the `INFOPLIST_KEY_` prefix there:

```yaml
INFOPLIST_KEY_NSLocationWhenInUseUsageDescription: "Shows your position and route on the map."
```

``LocationTrackerViewModel/access`` reports the result as an ``Access``, and ``LocationStatusView`` turns each state into what the user sees:

| ``Access`` | Cause | What the map shows |
|---|---|---|
| ``Access/unknown`` | Not asked yet, or waiting for the answer. | "Finding your location…" |
| ``Access/allowed`` | Access granted. | The dot. Before the first fix: "Finding your location…", or "Can't find your location right now." if ``LocationTrackerViewModel/isLocationUnavailable``. |
| ``Access/denied`` | Location is off for this app. | A banner with **Open Settings**. |
| ``Access/servicesOff`` | Location Services is off for the whole device. | A banner pointing to Privacy & Security, with **Open Settings**. |
| ``Access/restricted`` | Screen Time or a device profile blocks it. | A banner, without a Settings button, since the user may not be able to change it. |

`CLAuthorizationStatus` reports both denied and services-off as `.denied`. The tracker reads the more specific state from the live updates, so users get the right fix.

## Starting and Stopping Updates

Location runs only while the map is on screen. ``MapView`` calls ``LocationTrackerViewModel/activate()`` in `onAppear` and ``LocationTrackerViewModel/deactivate()`` in `onDisappear`:

- `activate()` asks for permission if it hasn't been decided yet, then streams positions with `CLLocationUpdate.liveUpdates()` and starts the compass. A `CLServiceSession` keeps When In Use access active for as long as updates run.
- `deactivate()` cancels the stream and the compass, so the sensors aren't used for a screen nobody sees.

Updates keep running while access is denied. That's how the tracker notices when the user turns access back on, and how the banner learns that Location Services is off.

The tracker stays alive between visits because ``ContentView`` owns it, not ``MapView``. To use location on another screen, pass the same instance instead of creating a second one. Two trackers would each run their own `CLLocationManager`:

```swift
// ContentView
@State private var mapTracker = LocationTrackerViewModel()

Tab("Nearby", systemImage: "location") {
    NavigationStack {
        NearbyView(tracker: mapTracker)
    }
}

// NearbyView
struct NearbyView: View {
    let tracker: LocationTrackerViewModel

    var body: some View {
        Group {
            if let location = tracker.location {
                Text("You're at \(location.latitude), \(location.longitude)")
            } else {
                LocationStatusView(tracker: tracker)
            }
        }
        .onAppear { tracker.activate() }
        .onDisappear { tracker.deactivate() }
    }
}
```

Don't add a second `activate()` call while ``MapView`` is also visible. The calls aren't counted, so the first `deactivate()` stops updates for both screens.

## Approximate Location

If the user turns off **Precise Location**, ``LocationTrackerViewModel/isApproximate`` is true and positions are only accurate to a few kilometers. The map adapts:

- It shows MapKit's shaded area instead of the dot, and tapping it does nothing, because the address under an approximate fix would be a guess.
- It frames about 10 km around the user instead of 1 km.

## Heading and the Cone

``LocationTrackerViewModel/heading`` is the direction the device faces, in degrees clockwise from north. It's `nil` when the compass is missing or less accurate than ±45°, and then the cone is hidden rather than pointing somewhere wrong.

The dot is drawn upright on screen while the map can rotate, so ``MapView`` subtracts the camera's heading before passing it to ``LocationIndicator``:

```swift
UserAnnotation {
    LocationIndicator(heading: tracker.heading.map { $0 - cameraHeading })
}
```

A device's heading is measured from its top edge, so ``MapView`` also calls ``LocationTrackerViewModel/setHeadingOrientation(_:)`` whenever the interface rotates.

## Framing the Camera

The map opens on the user at about 1 km across, like Apple Maps, and only once, on the first fix. After that the camera stays wherever the user moves it. Tapping the location button in ``MapControls`` returns to the same view.

Before the first fix, MapKit can only show a country-wide map, so ``MapView`` covers it with a blank background and the "Finding your location…" status. If access is denied or the position is unavailable, it shows the plain map with a banner instead.

## Searching for Places

``MapViewModel/search(in:)`` runs an `MKLocalSearch` for ``MapViewModel/query``, biased to the region on screen. It returns `true` when there are results, so the view can zoom out to include them:

```swift
@State private var model = MapViewModel()

MapSearchBar(query: $model.query) {
    Task {
        if await model.search(in: visibleRegion) {
            withAnimation { camera = .automatic }
        }
    }
}

// In the Map content:
ForEach(model.results, id: \.self) { Marker(item: $0) }
```

The view model handles errors itself. No results and no connection each set ``MapViewModel/errorMessage`` and ``MapViewModel/isShowingError``, which drive one alert:

```swift
.alert(model.errorMessage ?? "", isPresented: $model.isShowingError) { }
```

Clearing the search text also clears the markers.

## Showing the Address Under the Dot

Tapping the dot calls ``MapViewModel/showPlace(at:)``. It looks up the address with `MKReverseGeocodingRequest` and puts the result in ``MapViewModel/selectedPlace``. MapKit's own place card then shows it:

```swift
.mapItemDetailSheet(item: $model.selectedPlace, displaysMap: false)
```

## Reusable Views

These views take plain values, so you can use them outside ``MapView``.

``LocationIndicator`` draws the dot. Pass `nil` to hide the cone:

```swift
LocationIndicator(heading: 45)  // Cone points up and to the right.
LocationIndicator(heading: nil) // Dot only.
```

``MapControls`` stacks a traffic toggle above a recenter button, in one glass capsule:

```swift
MapControls(showsTraffic: $showsTraffic, canRecenter: tracker.location != nil) {
    withAnimation { camera = .userLocation(fallback: .automatic) }
}
```

``MapSearchBar`` is a glass search field that runs `search` when the user taps Search on the keyboard:

```swift
MapSearchBar(query: $query) { Task { await runSearch() } }
```

``LocationBanner`` shows a message, and optionally an **Open Settings** button that opens this app's page in Settings:

```swift
LocationBanner(message: "Location access is off for this app.", showsSettings: true)
```

## KRL Green Line Corridor

The map draws the KRL Green Line (Lin Rangkasbitung, Tanah Abang ↔ Rangkasbitung) and answers two questions about it. The header's segmented control switches between them through ``MapViewModel/activeMode``:

| ``CommuteScenarioMode`` | Question | Shows |
|---|---|---|
| ``CommuteScenarioMode/corridorIncidents`` | What's disrupting the line? | ``CorridorIncident`` pins within 3 km of a station, and a 3 km circle around each station. |
| ``CommuteScenarioMode/nearbyTransit`` | How else can I travel from here? | ``NearbyTransitPoint`` pins within 3 km of the user, and a 3 km circle around the user. |

Both use ``MapViewModel/maxRadiusMeters`` (3 km) and measure in a straight line, not walking distance.

> Note: The incidents and transit stops are hand-written sample data for the prototype (marked "Contoh Kurasi"), not live feeds. Swap ``CorridorIncident/curatedSamples`` and ``NearbyTransitPoint/catalog`` for real sources when they exist.

### The Data

All corridor data lives in `Core/Model` as static arrays, in `GreenLineCorridorData.swift` and `GreenLineTrack.swift`. In the documentation, these types are under **Models**:

| Data | Type | What it holds |
|---|---|---|
| ``GreenLineStation/all`` | ``GreenLineStation`` | 12 of the line's 19 stations, in order from Tanah Abang (``GreenLineStation/sequence`` 1). |
| ``CorridorIncident/curatedSamples`` | ``CorridorIncident`` | 4 sample incidents: a signalling fault, a protest, flooding, and roadworks. |
| ``NearbyTransitPoint/catalog`` | ``NearbyTransitPoint`` | 9 sample stops: TransJakarta, MRT, BSD Link, shuttles, and angkot. |
| ``GreenLineTrack/coordinates`` | `[CLLocationCoordinate2D]` | The real track shape, from OpenStreetMap. |

The green line follows ``GreenLineTrack``, not straight lines between stations, so it bends with the real track. It's generated by `scripts/green_line_track.py`; don't edit it by hand. Showing it requires the "Track © OpenStreetMap contributors" credit in the header.

### Adding a Station

Add it to ``GreenLineStation/all`` in line order, and renumber ``GreenLineStation/sequence`` for the stations after it. It appears as a marker, gets its own 3 km circle, and counts for both scenarios:

```swift
GreenLineStation(id: "CC", name: "Stasiun Cicayur", sequence: 10, latitude: -6.3300, longitude: 106.6182),
```

### Adding an Incident

Add a ``CorridorIncident`` to ``CorridorIncident/curatedSamples``. The values below are an example, not a real report. Only incidents within 3 km of a station appear; ``MapViewModel/corridorIncidents`` drops the rest.

```swift
CorridorIncident(
    id: "inc-005",
    title: "Perbaikan Rel di Petak Serpong–Cisauk, KRL Melambat",
    category: "service_disruption",     // or "incident"
    locationName: "Petak Serpong–Cisauk",
    latitude: -6.3226,
    longitude: 106.6533,
    nearestStationId: "SRP",            // a GreenLineStation id
    nearestStationName: "Stasiun Serpong",
    distanceToStationKm: 1.35,
    publishedAt: "18 Okt 2026 • 14:00 WIB",
    sourceName: "Info Resmi Commuter (Contoh)",
    verificationStatus: "verified"      // or "unverified"
)
```

`category`, `verificationStatus`, and `nearestStationId` are plain strings, so a typo compiles. Use only the values in the comments above. `distanceToStationKm` is shown as entered; work it out from the coordinates.

### Adding a Transit Stop

Add a ``NearbyTransitPoint`` to ``NearbyTransitPoint/catalog``. Leave ``NearbyTransitPoint/straightLineDistanceKm`` out; ``MapViewModel/nearbyTransits(from:)`` fills it in.

```swift
NearbyTransitPoint(
    id: "tr-10",
    name: "Halte Contoh Kebayoran",      // example values
    mode: "TransJakarta",
    routesInfo: "Rute contoh",
    latitude: -6.2385,
    longitude: 106.7827
)
```

To try Nearby Modes in Simulator, stand near a station, for example Kebayoran:

```bash
xcrun simctl location booted set -6.2373,106.7825
```

## Testing in Simulator

The simulator has no GPS or compass, so set a position yourself. Use **Features › Location** in the Simulator menu, or the command line:

```bash
# Put the device in central Jakarta.
xcrun simctl location booted set -6.2,106.8

# Walk between two points to draw the route.
xcrun simctl location booted start --speed=1.4 -6.2,106.8 -6.201,106.802

# Try each banner: deny access, then reset so the prompt shows again.
xcrun simctl privacy booted revoke location com.appleacademy.moobby
xcrun simctl privacy booted reset location com.appleacademy.moobby
```

There's no heading in the simulator, so the cone never appears there. Test it on a device.

## Topics

### Location

- ``LocationTrackerViewModel``
- ``Access``

### Screen

- ``MapView``
- ``MapViewModel``
- ``CommuteScenarioMode``

### Views

- ``LocationIndicator``
- ``Cone``
- ``MapControls``
- ``MapSearchBar``
- ``LocationStatusView``
- ``LocationBanner``
