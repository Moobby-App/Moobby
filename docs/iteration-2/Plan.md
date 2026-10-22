# Moobby — Iteration 2 Plan

> Proposed by the agent from `docs/iteration-2/SPEC.md` (v2). Status: **approved** (all five questions answered with the agent's suggestions; see `Decisions.md`).
> When reality differs from this plan, update the plan first, then the code.

## Folder structure (follows the existing `Features/Map` pattern)

```
moobby/
├── App/ContentView.swift                     (changed: tabs)
├── Core/Model/
│   ├── Station.swift                         (new)
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
| 0 | Read existing code before writing any: `GreenLineCorridorData`, `GreenLineTrack`, `Endpoint`, `FontStyle`, `GlassCard`, `project.yml`. Decide what to reuse. No code. | — | — |
| 1 | Models + the 20-station list + segment logic (stations between departure and destination, in order) | AC1, AC9, AC12 | `Station`, `Incident`, `TransJakartaStop` |
| 2 | Placeholder JSON + loading it (incidents, schedule, TJ stops) | AC24, AC13, AC14 (data) | `Resources/PlaceholderData/*` |
| 3 | `GetIncidentsRequest` (APIRequest) called via `container.api.execute(...)`; fall back to placeholder while the API returns `[]` | AC16, AC19, AC20 (data) | `GetIncidentsRequest` |
| 4 | Swap tabs in `ContentView`: Berita + Rute replace Map + Components (iteration 1 code stays) | OQ8 | `ContentView` |
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

## Assumptions
1. Placeholder JSON files inside `moobby/` are picked up as app resources by XcodeGen (to be checked in Task 0 against `project.yml`).
2. Station IDs in our list will be our own (e.g. `sudimara`); mapping to backend `nearestStationId` waits for Open question 6.
3. The selected route is shared between tabs through one `@Observable` object created in `ContentView` and passed to both tabs. It is session state, not an app-wide service, so it does **not** go into `AppContainer`. (To log in `Decisions.md` if approved.)
4. `APIConfig.baseURL` is **not** changed to the temporary tunnel URL in this branch (see Questions).

## Answered questions
1. **Tabs:** Berita + Rute replace Map + Components in `TabView`; iteration 1 code stays. ✅
2. **F1:** later, after Task 12. ✅
3. **Unit tests:** no new test target for the POC; *(Unit)* ACs checked by hand. ✅
4. **Backend URL:** placeholder data in this branch; switch the URL when it's stable. ✅
5. **Names:** English folder and type names (`News`, `Route`); UI text in Bahasa Indonesia. ✅
