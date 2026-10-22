# Iteration 2: Berita & Kondisi Rute

What was built on branch `feat/berita-kondisi-rute`, how it fits together, and how to check it.
Spec, plan and decisions: `docs/iteration-2/` (`SPEC.md`, `Plan.md`, `Decisions.md`).

## What the user sees

| Tab | Screens |
|---|---|
| **Berita** | Latest Green Line news (up to 3 orange cards, "N berita"), "Lihat semua berita" → Semua Berita, tap a card → Detail Berita. After a route is picked in tab Rute, the tab shows only news on that route. |
| **Rute** | Pilih Rute Perjalanan (two search fields + station list) → Kondisi Rute (header, "N stasiun terdampak" banner, timeline with estimated times and ⚠️). An affected station's "Detail Berita" shows its news and TransJakarta stop chips; a chip opens Apple Maps walking directions. |

Iteration 1's Map and Components tabs are no longer shown; their code is unchanged.

## How the code fits together

```
MoobbyApp ─▶ AppContainer (api, localData, locationPermission, …)
   └─▶ ContentView ── @State RouteSelection (shared, not saved)
         ├─ Tab Berita: NewsView ◀─ NewsViewModel ─▶ IncidentFeed ─▶ localData / api
         │      └─ NewsRoute: AllNewsView, NewsDetailView
         └─ Tab Rute:   RouteSelectionView ◀─ RouteSelectionViewModel ─▶ RouteSelection
                └─ RouteScreen: RouteConditionView ◀─ RouteConditionViewModel
                       └─ StationRow ─ StationDetailPanel ─▶ Apple Maps (after location check)
```

| Area | Files |
|---|---|
| Models | `Core/Model/GreenLineStation+FullLine.swift`, `Incident.swift`, `TransJakartaStop.swift`, `TravelSchedule.swift` |
| Data | `Core/Storage/LocalData.swift`, `Resources/PlaceholderData/*.json`, `Core/Networking/IncidentFeed.swift`, `Core/Networking/Requests/GetIncidentsRequest.swift` |
| Location | `Core/Location/LocationPermission.swift`, `Features/Route/TransJakartaStop+Maps.swift` |
| Tab Berita | `Features/News/…` |
| Tab Rute | `Features/Route/…` |
| Changed team files | `App/ContentView.swift` (tabs), `Core/DI/AppContainer.swift` (two new dependencies: `localData`, `locationPermission`) |

## Connecting the real backend

1. Put the team backend's URL in `APIConfig.baseURL` (`Core/Networking/APIClient.swift`).
2. Change `IncidentFeed.defaultSource` from `.placeholder` to `.backend`.

With `.backend`, an empty list shows "Belum ada informasi gangguan" and a network error shows "Coba lagi" (no fallback to placeholder data). Replace `schedule.json` and `transjakarta_stops.json` when real data exists.

## How to check each criterion

Run the app on an iPhone simulator. Previews: "Segment check" (`GreenLineStation+FullLine`), "Incident rules check" (`Incident`), "Placeholder data check" (`LocalData`), "Incident feed check" (`IncidentFeed`).

| AC | Check |
|---|---|
| AC16 | Tab Berita: 3 cards, newest first (Kebayoran, Palmerah, Sudimara), "4 berita" |
| AC17 | "Lihat semua berita" → 4 cards |
| AC18 | Tap a card → Detail Berita with title, category, station, time, source, status |
| AC19 | Make `incidents.json` `[]` → "Belum ada informasi gangguan" |
| AC20 | Needs `.backend` source: turn off the Mac's network → message + "Coba lagi" |
| AC21 | Tab Rute: empty fields, stations Rangkasbitung → Tanah Abang |
| AC22 | Type `jurang` → only Jurangmangu |
| AC23 | Pick two stations → Kondisi Rute opens |
| AC1, AC9, AC12 | Kebayoran → Cisauk shows the 7 stations in order; Palmerah's news isn't on it |
| AC10, AC25 | Kebayoran → Cisauk: ⚠️ on Kebayoran, Sudimara, Cisauk; "3 stasiun terdampak" |
| AC11 | Rawa Buntu → Serpong: no ⚠️, no banner |
| AC24 | Times go up 4 minutes per station |
| AC26 | "Detail Berita" only on ⚠️ stations; opens and closes |
| AC13, AC14 | Kebayoran has 2 chips; Sudimara has none |
| AC27 | Allow location → tap a chip → Apple Maps walking directions |
| AC15 | Set Moobby's location to Never (or launch with `-simulateLocationDenied`) → tap a chip → "Izin lokasi dibutuhkan", Maps doesn't open |
| AC28 | Pick Rawa Buntu → Cisauk → tab Berita shows "Rute Rawa Buntu – Cisauk", 1 berita |

## Known gaps

- **3 stations missing**: Cikoya, Tenjo and Jatake wait for codes and coordinates from the backend (SPEC open question 8).
- **F1 Live Location Tracking (AC2–AC8)** is deferred (Decision 11): no position marker, no faded passed stations.
- **Placeholder data**: incidents come from iteration 1's samples; two of them are events near stations, not KRL disruptions.
- **`ComponentScreenshotTests` fails**: it taps the Components tab, which isn't shown any more (SPEC open question 15).
- **Location prompt text** in `project.yml` is still iteration 1's English text (SPEC open question 16).
- **No unit tests**: the project has no unit test target; *(Unit)* criteria are checked by hand and in the Previews above.
