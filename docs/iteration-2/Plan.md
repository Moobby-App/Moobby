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
| 5 | Tab Berita: up to 3 cards (orange), count label, loading / empty / error | AC16, AC19, AC20 | `NewsViewModel`, `NewsView`, `NewsCard` |
| 6 | "Lihat semua berita" + Detail Berita page (HIG), navigation with a `Hashable` route enum | AC17, AC18 | `AllNewsView`, `NewsDetailView` |
| 7 | Pilih Rute: two empty fields, 20 stations, filter while typing, open Kondisi Rute after both are picked | AC21, AC22, AC23 | `RouteSelectionViewModel`, `RouteSelectionView` |
| 8 | Kondisi Rute: header, timeline with times, ⚠️ on affected stations, banner "N stasiun terdampak", header ⚠️ | AC1, AC9, AC10, AC11, AC12, AC24, AC25 | `RouteConditionViewModel`, `RouteConditionView`, `StationRow` |
| 9 | Detail Berita toggle on affected stations, with TJ stop chips | AC26, AC13, AC14 | `StationDetailPanel` |
| 10 | Tap a chip → Apple Maps directions; location denied → message + Settings button | AC27, AC15 | `StationDetailPanel` |
| 11 | Berita follows the selected route (shared state between tabs) | AC28 | `RouteSelection` |
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
