# Moobby — Iteration 2 Plan

> Proposed by the agent from `docs/iteration-2/SPEC.md` (v2). Status: **approved** (all five questions answered with the agent's suggestions; see `Decisions.md`).
> When reality differs from this plan, update the plan first, then the code.

## Folder structure (follows the existing `Features/Map` pattern)

```
moobby/
├── App/ContentView.swift                     (changed: tabs)
├── Core/Model/
│   ├── GreenLineStation+FullLine.swift       (new: 20-station list, reuses the iteration 1 type)
│   ├── Incident.swift                        (new)
│   └── TransJakartaStop.swift                (new)
├── Core/Networking/Requests/
│   └── GetIncidentsRequest.swift             (new)
├── Resources/PlaceholderData/                (new, POC only)
│   ├── incidents.json
│   ├── schedule.json
│   └── transjakarta_stops.json
└── Features/
    ├── News/                                 (tab "Berita")
    │   ├── NewsViewModel.swift
    │   └── View/
    │       ├── NewsView.swift
    │       ├── NewsCard.swift
    │       ├── AllNewsView.swift
    │       └── NewsDetailView.swift
    └── Route/                                (tab "Rute")
        ├── RouteSelectionViewModel.swift
        ├── RouteConditionViewModel.swift
        ├── RouteSelection.swift              (shared selected-route state)
        └── View/
            ├── RouteSelectionView.swift
            ├── RouteConditionView.swift
            ├── StationRow.swift
            └── StationDetailPanel.swift
```

Code and folder names in English (like the existing code); all UI text in Bahasa Indonesia (spec Constraints).

## Tasks

Each task: build → check → commit, one at a time.

| # | Task | ACs | Files |
|---|---|---|---|
| 0 | ✅ Done. Read existing code (see "Task 0 findings" below). | — | — |
| 1a | ✅ Done. 20-station list (17 for now) + segment logic in both directions; checked in the "Segment check" Preview | AC1, AC21 (partly) | `GreenLineStation+FullLine` |
| 1b | ✅ Done. `Incident` (optional API fields, segment filter, affected stations counted once, newest first) and `TransJakartaStop`; checked in the "Incident rules check" Preview | AC9, AC12, AC25, AC13, AC14 (logic) | `Incident`, `TransJakartaStop` |
| 2 | ✅ Done (after Preview check). Placeholder JSON from iteration 1 samples + `BundledJSONData` reached through `AppContainer.localData`; checked in the "Placeholder data check" Preview | AC24, AC13, AC14 (data) | `Resources/PlaceholderData/*`, `TravelSchedule`, `Core/Storage/LocalData`, `AppContainer` (one new dependency) |
| 3 | ✅ Done (after Preview check). `GetIncidentsRequest` (APIRequest, no URL in the file) + `IncidentFeed`, which reads placeholder JSON or the backend from one switch (`IncidentFeed.defaultSource`); checked in the "Incident feed check" Preview | AC16, AC19, AC20 (data) | `Core/Networking/Requests/GetIncidentsRequest`, `Core/Networking/IncidentFeed` |
| 4 | ✅ Done (after simulator check). Tabs Berita + Rute replace Map + Components; each tab shows a placeholder view until Tasks 5 and 7. Iteration 1 code stays; `ContentView` no longer creates the Map's location tracker | Constraints → Iteration | `ContentView`, `NewsView` (placeholder), `RouteSelectionView` (placeholder) |
| 5 | ✅ Done (after simulator check). `NewsViewModel` (loading / loaded / failed, newest 3, count label) + `NewsView` + `NewsCard` (orange) + non-tappable Green Line badge. Card description falls back to `locationName` while the API has no description | AC16, AC19, AC20 | `NewsViewModel`, `NewsView`, `NewsCard`, `ContentView` |
| 6 | ✅ Done (after simulator check). `NewsRoute` (`allNews`, `detail`) with `navigationDestination(for:)`; "Lihat semua berita" opens Semua Berita (all incidents, same states, shares the tab's ViewModel); tapping a card opens Detail Berita (grouped list: category, title, station, location, distance, time, source, verification) | AC17, AC18 | `NewsRoute`, `AllNewsView`, `NewsDetailView`, `NewsView`, `NewsCard` |
| 7 | ✅ Done (after simulator check). `RouteSelectionViewModel` (two queries, filter ignoring case/accents and the "Stasiun" prefix, departure disabled as destination, opens Kondisi Rute through `path` once both are picked) + `RouteSelectionView` + `RouteScreen`. `RouteConditionView` is a placeholder listing the segment until Task 8 | AC21, AC22, AC23, AC1 | `RouteScreen`, `RouteSelectionViewModel`, `RouteSelectionView`, `RouteConditionView` (placeholder), `ContentView`, `GreenLineStation+FullLine` (`shortName`) |
| 8 | ✅ Done (after simulator check). `RouteConditionViewModel` (segment + incidents on it + estimated times, loading / loaded / failed) + `RouteConditionView` (header with ⚠️, banner "N stasiun terdampak" only when N ≥ 1, timeline) + `StationRow`. Position marker and faded passed stations wait for F1 | AC1, AC9, AC10 (⚠️ part), AC11, AC12, AC24, AC25 | `RouteConditionViewModel`, `RouteConditionView`, `StationRow`, `RouteSelectionViewModel` (now gets the container), `ContentView` |
| 9 | ✅ Done (after simulator check). "Detail Berita" toggle only on affected stations; opens `StationDetailPanel` with the station's incidents (title, description, source · time) and its TransJakarta stop chips, or no chips when there are none | AC26, AC10 (source and time), AC13, AC14 | `RouteConditionViewModel`, `StationRow`, `StationDetailPanel` |
| 10 | ✅ Done (after simulator check). Stop chips are buttons: Moobby asks for its own location permission if needed; allowed → Apple Maps walking directions to the stop; denied → "Izin lokasi dibutuhkan" alert with "Buka Pengaturan", Maps not opened. `-simulateLocationDenied` launch argument for testing | AC15, AC27 | `Core/Location/LocationPermission` (new `AppContainer` dependency), `TransJakartaStop+Maps`, `RouteConditionViewModel`, `RouteConditionView`, `StationRow`, `StationDetailPanel` |
| 11 | ✅ Done (after simulator check). `RouteSelection` (shared, not saved) created in `ContentView`; tab Rute sets it when both stations are picked and clears it when a field is cleared; tab Berita shows only news on that segment with "Rute …" under the title, or "Tidak ada gangguan di rute ini" when there's none. Semua Berita still lists every Green Line incident | AC28 | `RouteSelection`, `ContentView`, `RouteSelectionViewModel`, `NewsViewModel`, `NewsView` |
| 12 | Write `/docs-<feature>` notes, run the pre-PR checklist | DoD | `docs-...` |

## Later (not in this plan)
- F1 Live Location Tracking (AC2–AC8): its own plan after Task 12.

## Task 0 findings
- `project.yml` builds everything under `moobby/` into the app, so placeholder JSON there is bundled automatically (assumption 1 confirmed).
- `GreenLineStation` (iteration 1) already models a station: code (`"KBY"`), name, sequence from Tanah Abang (1), coordinates. Its `all` list has only 12 stations.
- `CorridorIncident` has the same field names as the backend API, but every field is required and `publishedAt` is pre-formatted text, so it can't decode API responses where fields are missing.
- `CorridorIncident.curatedSamples` and `NearbyTransitPoint.catalog` are sample data that can seed the placeholder JSON.
- `Core/UI`: `.typography(.title / .body / .button / .caption)` and `.glassCard(cornerRadius:)`.
- Only "When In Use" location permission exists (iteration 1). Opening Apple Maps uses Maps' own location permission, so AC15 may not be needed; to decide before Task 10.
- Station codes: 12 from iteration 1, 5 from Wikipedia (CTR, TGS, DAR, CJT, CC). **Cikoya, Tenjo and Jatake are missing**; ask the backend developer.

## Assumptions
1. ~~Placeholder JSON files inside `moobby/` are picked up as app resources by XcodeGen.~~ Confirmed in Task 0.
2. Backend `nearestStationId` uses the same station codes as iteration 1 (e.g. `"KBY"`), because the API fields match `CorridorIncident`, whose `nearestStationId` is a `GreenLineStation.id`. To confirm (Open question 6).
3. The selected route is shared between tabs through one `@Observable` object created in `ContentView` and passed to both tabs. It is session state, not an app-wide service, so it does **not** go into `AppContainer`. (To log in `Decisions.md` if approved.)
4. `APIConfig.baseURL` is **not** changed to the temporary tunnel URL in this branch (see Questions).

## Answered questions
1. **Tabs:** Berita + Rute replace Map + Components in `TabView`; iteration 1 code stays. ✅
2. **F1:** later, after Task 12. ✅
3. **Unit tests:** no new test target for the POC; *(Unit)* ACs checked by hand. ✅
4. **Backend URL:** placeholder data in this branch; switch the URL when it's stable. ✅
5. **Names:** English folder and type names (`News`, `Route`); UI text in Bahasa Indonesia. ✅
