# Moobby — Iteration 2 Decisions

Why we chose what we chose. Newest at the bottom. "Agent suggestion" = proposed by the agent and accepted by the developer.

| # | Decision | Why | Alternatives considered | Source |
|---|---|---|---|---|
| 1 | iOS 26.5 or later | Matches `project.yml`; team conventions use Liquid Glass (iOS 26+) | iOS 17 (draft v1) | Team |
| 2 | TransJakarta stops shown in the Detail Berita of an affected station | Stops matter when a station is disrupted | Stops within 1 km of the user | Team |
| 3 | Tapping a stop opens Apple Maps | Much smaller than an in-app map for a POC | In-app map with MapKit route | Team |
| 4 | Directions go only to the stop | Full multimodal routing is out of scope | Route continuing on TransJakarta | Team |
| 5 | Selected route is not saved | Simplest for a POC | Prefill last route; recent routes list | Team |
| 6 | Banner counts affected stations, not incidents | Matches the "N stasiun terdampak" text | Count incidents | Team |
| 7 | No "delayed / normal" label; ⚠️ and banner only | Matches the design | Status label | Team |
| 8 | All news cards orange | Every card is a disruption | Orange vs grey by status | Team |
| 9 | States without a design use built-in iOS components | Already follow Apple HIG; less work | Custom design for each state | Team |
| 10 | Iteration 2 tabs replace iteration 1 tabs; iteration 1 code stays in the repo | Show the new design, keep the old work recoverable | Add tabs next to the old ones; delete old code | Team |
| 11 | F1 Live Location Tracking deferred | Largest and riskiest part; ship the two main screens first | Build F1 now | Agent suggestion |
| 12 | No unit test target for the POC | Adding one changes `project.yml` and needs a team decision | Add a unit test target now | Agent suggestion |
| 13 | Placeholder data; `APIConfig.baseURL` unchanged for now | The tunnel URL is temporary and would break the app when it changes | Commit the tunnel URL | Agent suggestion |
| 14 | English folder and type names | Consistent with existing code (`Map`, `Components`) | Indonesian names | Agent suggestion |
| 15 | Selected route shared through an `@Observable` object created in `ContentView` | Session state, not an app-wide service, so it doesn't belong in `AppContainer` | Put it in `AppContainer`; save it in `store` | Agent suggestion |
| 16 | Reuse the iteration 1 `GreenLineStation` type; add the 20-station list in a new file | Same station codes as the backend (`"KBY"`), and no iteration 1 file is edited | New `Station` model for iteration 2 | Agent suggestion |
| 17 | New `Incident` model for API data, with optional fields | The API can leave fields empty; `CorridorIncident` requires all of them | Reuse `CorridorIncident` | Agent suggestion |
| 18 | Station codes and coordinates come from the iteration 1 list and Wikipedia; Cikoya, Tenjo and Jatake wait for the backend developer | Don't invent data | Estimate the missing values | Agent suggestion |
| 19 | Both travel directions allowed | Commuters go to Jakarta and back; the design's example (Kebayoran – Cisauk) goes away from Jakarta | One direction only | Agent suggestion |
| 20 | The departure station can't be picked as the destination | The same-station case can't happen, so no error message is needed | Allow it and show an error | Agent suggestion |
| 21 | Placeholder data is converted from iteration 1 samples (`curatedSamples`, TransJakarta stops in `catalog`) | Don't invent data; MRT, angkot and shuttle stops are out of scope | Write new sample data | Agent suggestion |
| 22 | Estimated times = departure time + a fixed number of minutes per station from `schedule.json` | No real KRL schedule exists yet (open question 9) | Hard-code times per station | Agent suggestion |
| 23 | Local data is a new `AppContainer` dependency (`localData`), following the "Adding a dependency" steps in `AppContainer` | Team convention: dependencies come from `AppContainer`; previews can pass fake data | Load JSON directly inside each ViewModel | Agent suggestion |
| 24 | Incidents come from one switch, `IncidentFeed.defaultSource` (`.placeholder` in this branch); with `.backend`, an empty list stays empty and errors are shown, with no automatic fallback | Keeps AC19 (empty state) and AC20 (error state) true for the real backend; the current base URL isn't the team backend, so calling it would always fail | Call the backend and fall back to placeholder data when it's empty or fails | Agent suggestion |
| 25 | Moobby checks its own location permission before opening Apple Maps; denied → alert with "Buka Pengaturan", Maps not opened (AC15 kept) | Developer's choice: keep AC15 as written | Always open Apple Maps and let Maps handle its own location permission (agent suggestion, not chosen) | Team |
| 26 | Location permission is a new `AppContainer` dependency (`locationPermission`), with a `-simulateLocationDenied` launch argument | Team convention (dependencies from `AppContainer`); lets a UI test check AC15 (SPEC Notes for the Agent) | Use `CLLocationManager` directly in the ViewModel | Agent suggestion |
