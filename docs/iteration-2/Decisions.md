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
