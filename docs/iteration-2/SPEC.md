# Moobby — SPEC (v2)

> v2 = revisi dari draf v1 berdasarkan keputusan tim. Baris yang ditandai **(agent)** adalah saran agent, bukan keputusan tim — baca dan setujui atau hapus. Daftar lengkap perubahan ada di bagian paling bawah.

## Opportunity Statement
New commuters need a way to know if their route is delayed or has changed, from before they leave, at the station, and throughout the trip, and which nearby modes they can take when they are directly affected by a disruption, because they only know one route and get confused when their usual route suddenly changes.

## Persona
Looqman, 24 years old
A worker and new commuter in Jabodetabek who takes the KRL Green Line and TransJakarta to work every day. He only knows one route for his daily commute.

- Goal: know what to do when his route is disrupted, without waiting in uncertainty.
- Frustration: when his route is suddenly delayed or changed, he doesn't know where to go. He ends up waiting a long time without any certainty, following the crowd, asking station security, or being forced to take an ojol (online motorcycle taxi) at a higher cost. He also often only finds out about a disruption after he has already arrived at the station.

## App Statement
For new commuters on the KRL Green Line who only know one route, Moobby is an iOS app that tells them when their route is delayed or has changed, before they leave and during the trip, and shows nearby TransJakarta options when they are affected by a disruption. Unlike Google Maps, which mainly gives directions when users search for a route, or asking station security and following the crowd, Moobby watches their daily route and gathers disruption news for them, so they can decide how to reach their destination instead of waiting without certainty.

## Core Loop
1. Select the departure and destination station. **(agent)**
2. Check the Green Line condition for that segment.
3. If there's a disruption, see the disruption detail and the TransJakarta stops near the affected station.
4. Wait on the usual route, or walk to a TransJakarta stop if it takes too long.

## MVP Features (must ship)
- **F1 — Live Location Tracking:** Track the user's position along the selected Green Line segment, including in the background, and show their movement from station to station.
- **F2 — Disruption Information:** **(agent: berita digabung ke F2 karena panduan membatasi maksimal 3 fitur MVP)**
  - **F2a — Berita (tab 1):** a list of Green Line disruption news, a "Lihat semua berita" button, and a news detail page.
  - **F2b — Kondisi Rute (tab 2):** the user always selects a departure and destination station first (whether location is allowed or denied). Then the app shows the stations of that segment with estimated times, marks affected stations, and shows the disruption detail on each affected station.
- **F3 — Nearby TransJakarta:** In the disruption detail of an affected station, show the TransJakarta stops connected to that station as tappable options. Tapping one opens Apple Maps with directions from the user's current location to that stop.

## Out of Scope
- AI-based route recommendations and predictions
- Full multimodal route planning, including any TransJakarta route after the stop (directions go only from the user to the stop)
- An in-app map or in-app route drawing (directions open in Apple Maps)
- Remembering the last selected route
- News about TransJakarta services, or any news that is not a KRL Green Line disruption
- Automatic notifications
- Coverage of KRL lines other than the Green Line
- Online motorcycle taxis (ojol), online taxis, and transport modes other than the KRL Green Line and the TransJakarta stops connected to it

## Constraints

### Platform
- iPhone, **iOS 26.5 or later** (matches `deploymentTarget` in `project.yml`), SwiftUI, Core Location, MapKit (only to open Apple Maps)
- Bahasa Indonesia only
- An internet connection is required

### Stations
- Default route: KRL Green Line (Rangkasbitung – Tanah Abang); no line selection
- Station list and order (source of truth; use these exact names):
  1. Rangkasbitung
  2. Citeras
  3. Maja
  4. Cikoya
  5. Tigaraksa
  6. Daru
  7. Tenjo
  8. Cilejit
  9. Parung Panjang
  10. Jatake
  11. Cicayur
  12. Cisauk
  13. Serpong
  14. Rawa Buntu
  15. Sudimara
  16. Jurangmangu
  17. Pondok Ranji
  18. Kebayoran
  19. Palmerah
  20. Tanah Abang
- The user's segment = all stations from the departure station to the destination station, inclusive, in the order above.

### Data
- Disruption data comes from the team backend (`GET /api/v1/incidents`). The base URL is set only in `APIConfig.baseURL` in `moobby/Core/Networking/APIClient.swift`; don't hardcode it anywhere else.
- An incident belongs to a station through its `nearestStationId` / `nearestStationName`.
- Use placeholder JSON for incidents while the API returns an empty list.
- Estimated station times and TransJakarta stops (name + coordinates per station) come from local JSON for the prototype.

### Rules
- News and route condition show KRL Green Line disruptions only.
- A station is **affected** when at least one incident belongs to it.
- There is no "delayed" / "normal" status label. Disruption is shown only through ⚠️ on affected stations and the banner.
- The banner counts **affected stations, not incidents** (2 incidents at Sudimara = "1 stasiun terdampak").
- Only affected stations show ⚠️ and a "Detail Berita" toggle.
- The route header shows ⚠️ when at least one station in the segment is affected.
- News relevance: before a route is selected in this session, tab Berita shows the latest Green Line incidents. After a route is selected, it shows only incidents on that segment.
- News time = the time from the news itself (`publishedAt`). No "BARU" label.
- Location is tracked in the background and requires "Always" location permission (F1).
- The selected route is not saved; the station fields are empty every time the app opens.

### Team conventions
- SwiftUI + MVVM. View stays thin; logic lives in the ViewModel. One view type per file.
- ViewModel uses `@Observable` + `@MainActor`, owned by the view with `@State`. No `ObservableObject` / `@Published`.
- Dependencies come from `AppContainer`; no new singletons.
- Network requests are structs conforming to `APIRequest`, called from the ViewModel via `container.api.execute(...)`.
- Styling uses `Core/UI` (`.typography(...)`, `.glassCard()`, `.buttonStyle(.glass)`).
- Navigation uses `navigationDestination(for:)` with a `Hashable` route enum.
- The Xcode project is generated with XcodeGen from `project.yml`; `.xcodeproj` is never committed. Run `xcodegen generate` after adding, removing or moving files.

## Screens and States

States without a design (loading, empty, error, normal route condition, location-denied message, empty search result, Detail Berita page) use built-in iOS components, such as `ProgressView`, `ContentUnavailableView` and standard alerts, following Apple HIG.

### Tab "Berita" — title "Berita Perjalanan" **(agent: nama tab)**
- "Green Line" label under the app title: informational only, not tappable. It tells the user the app covers the Green Line only.
- Normal: up to 3 incidents **(agent: angka 3 dari desain)**, following the news relevance rule. Each card shows title, description (see Open questions) and the news time. All news cards use the same orange style.
- Count label (e.g. "3 berita") = the number of incidents that match the news relevance rule.
- "Lihat semua berita" button.
- Loading: progress indicator.
- Empty: "Belum ada informasi gangguan".
- Error (no internet): a message and a "Coba lagi" button.

### Semua Berita
- Full list of Green Line incidents; same loading, empty and error states.

### Detail Berita (page, Apple HIG)
- Title, category, station, published time, source and verification status. (Description: see Open questions.)

### Tab "Rute" — Pilih Rute Perjalanan **(agent: nama tab)**
- Two empty search fields: "cari stasiun keberangkatan", "cari stasiun tujuan".
- List of all 20 stations in line order, filtered as the user types.
- Empty search result: "Stasiun tidak ditemukan". **(agent)**

### Kondisi Rute
- Header: "Green Line" and "[departure] – [destination]", with ⚠️ when at least one station in the segment is affected.
- Banner "N stasiun terdampak", only when N ≥ 1. When N = 0, no banner and no ⚠️.
- Station timeline in segment order, with estimated time per station, ⚠️ on affected stations and the user's position marker (F1).
- Station styles: passed stations are faded. The user's position and not-yet-passed stations follow Apple HIG.
- Affected station: "Detail Berita" toggle. When expanded: the station's incidents and its TransJakarta stop chips (chips only, no extra chevron).
- Loading and error (no internet) states as in tab Berita.

## Acceptance Criteria
Format: Given — When — Then. Tags show how each criterion is checked. **(agent: semua tag)**
IDs AC1–AC15 are kept from v1 so old references still work; new criteria start at AC16.

### F1 — Live Location Tracking
- **AC1** Given the user has selected a departure station and a destination station, when the route condition opens, then the app shows the Green Line stations from the departure station to the destination station, in the station-list order. *(UI)*
- **AC2** Given the user grants "Always" location permission, is within 1 km of a Green Line station, and is moving faster than 20 km/h *(default)*, when they open the app, then the user is considered to be on a trip and a position marker appears on the nearest station. *(Unit)*
- **AC3** Given the user is on a trip, when they are within 200 m *(default)* of the next station, then the marker moves to that station and the previous station is shown as passed (faded). *(Unit)*
- **AC4** Given the user is on a trip, when the train stops or is held (speed drops), then the marker stays on the last station passed. *(Unit)*
- **AC5** Given the user is on a trip, when they arrive at the destination station, then the trip is considered finished and the position marker disappears. *(Unit)*
- **AC6** Given the app was in the background while the user moved between stations, when they open the app again, then the marker shows the last station they passed, without a manual refresh. *(Manual)*
- **AC7** Given the user is not yet detected on a trip (e.g. standing still or walking near a station), when they open the app, then the station list is shown without a position marker. *(Unit)*
- **AC8** Given the user denies location permission, when they open the app, then the app still works and the station list is shown without a position marker. *(UI)*

### F2a — Berita
- **AC16** Given no route has been selected in this session, when the user opens tab Berita, then up to 3 latest Green Line incidents are shown, each with title, description and news time. *(UI)*
- **AC28** Given the user has selected a route in tab Rute, when they open tab Berita, then only incidents on that segment are shown, and the count label shows how many there are. *(Unit)*
- **AC17** Given tab Berita is shown, when the user taps "Lihat semua berita", then all Green Line incidents are listed. *(UI)*
- **AC18** Given a list of incidents, when the user taps one, then the Detail Berita page opens with its title, category, station, published time, source and verification status. *(UI)*
- **AC19** Given the backend returns an empty list, when the user opens tab Berita, then "Belum ada informasi gangguan" is shown. *(UI)*
- **AC20** Given there is no internet connection, when the user opens tab Berita, then an error message and a "Coba lagi" button are shown, and the app doesn't crash. *(UI)*

### F2b — Kondisi Rute
- **AC21** Given the app has just been opened, when the user opens tab Rute, then both station fields are empty and all 20 stations are listed in line order. *(UI)*
- **AC22** Given the station list is shown, when the user types part of a station name, then only stations whose name contains that text are listed. *(Unit)* **(agent)**
- **AC23** Given the user has selected a departure and a destination station, when the second station is selected, then the Kondisi Rute screen opens for that segment. *(UI)*
- **AC24** Given a segment is shown, when the route condition loads, then each station shows its estimated time from the local schedule data. *(Unit)*
- **AC9** Given the user has selected a departure station and a destination station, when they view the route condition, then only KRL disruptions on that Green Line segment are shown. *(Unit)*
- **AC10** Given an active disruption on the user's segment, when they view the route condition, then the affected station shows ⚠️, and its Detail Berita shows each disruption's source and time. *(UI)*
- **AC11** Given no active disruption on the user's segment, when they view the route condition, then no station shows ⚠️ and no banner is shown. *(Unit)*
- **AC12** Given a disruption outside the user's segment, when they view the route condition, then that disruption is not shown. *(Unit)*
- **AC25** Given incidents belong to N different stations in the segment, when the route condition loads, then the banner shows "N stasiun terdampak" and exactly those N stations show ⚠️ (two incidents at one station count as one). *(Unit)*
- **AC26** Given a station is affected, when the user taps "Detail Berita", then it expands to show that station's incidents and its TransJakarta stop chips; stations that are not affected have no "Detail Berita". *(UI)*

### F3 — Nearby TransJakarta
- **AC13** Given an affected station's detail is expanded, when the station has TransJakarta stops in the local data, then each stop is shown as a chip with its name. *(UI)*
- **AC14** Given an affected station's detail is expanded, when the station has no TransJakarta stops in the local data, then no chips are shown. *(UI)*
- **AC15** Given location permission is denied, when the user taps a stop chip, then a message explaining why location is needed and a button to open Settings are shown, and Apple Maps doesn't open. *(UI)*
- **AC27** Given location permission is allowed, when the user taps a stop chip, then Apple Maps opens with directions from the user's current location to that stop. *(Manual)*

## Definition of Done
- `xcodegen generate` runs and the app builds without errors.
- Every acceptance criterion passes, with evidence (test output, screenshot or Preview).
- Nothing from Out of Scope was added.
- All Constraints and team conventions are followed; no `.xcodeproj` is committed.
- A `.md` file about the feature is saved in `/docs-<feature>`.

## Open Questions

### For the backend developer
1. Is there a description or body field for the Detail Berita page? The API documentation only has `title`.
2. How do we know whether an incident is still active or already resolved?
3. Is `publishedAt` the time the disruption started, or only the time it was published?
4. What values can `verificationStatus` have, and should unverified incidents be shown?
5. Where should an incident without `nearestStationId` be shown?
6. Do the `nearestStationId` values match the station names/IDs in our station list? **(agent)**
7. Can we get one real example response? The API currently returns `[]`, so the fields haven't been checked.

### For the team
8. Do tabs "Berita" and "Rute" replace the existing tabs (e.g. Map) or get added to them?
9. Where will estimated station times come from after the prototype, and should they change when there is a disruption? (Watch out for "predictions" in Out of Scope.)
10. Where will TransJakarta stop data come from after the prototype?
11. What happens if the departure and destination station are the same?
12. Can the user travel in either direction (e.g. Kebayoran → Cisauk and Cisauk → Kebayoran)? **(agent)**
13. Are third-party packages allowed? **(agent)**
14. Does "Lihat semua berita" show all Green Line incidents, or only those matching the news relevance rule? **(agent)**
15. What does tab Berita show when a route is selected but it has no incidents? **(agent)**
## Notes for the Agent
- Propose a plan before writing any code. Break it into small numbered tasks, link each to the ACs it covers, and list the files you'll create.
- List your assumptions and questions. Ask; don't guess.
- Implement one task at a time and tell me how to check it.
- Write the test for each tagged criterion in the same task as the code, and show the test output as evidence. For UI tests, also give me the screenshot path.
- To test the location-denied states (AC8, AC15) in a UI test, use a launch argument that simulates denied access.
- To test trip detection and station changes (AC2–AC7), use simulated locations (e.g. a GPX file) that move along the Green Line at train speed.
- Use placeholder JSON for incidents, estimated times and TransJakarta stops if the real data isn't in the project yet, and tell me which files to replace.
- `README_MOOBBY_GATEWAY_SWIFT.md` describes the API data shape only. Don't copy its code as is; follow the Team conventions above. **(agent)**
- Add `///` doc comments on every public type and function, mentioning the AC they cover (e.g. `/// Covers AC25`). **(agent, dari panduan SDD)**
- After finishing each feature, write a `.md` file about what you built and save it in `/docs-<feature>`.
- Don't add anything that isn't in this spec.

---

## Changes in v2

### From team decisions
- iOS 17 → iOS 26.5, matching `project.yml`.
- Added team conventions to Constraints.
- Added the 20-station list as the source of truth.
- Added news list, "Lihat semua berita" and news detail (F2a, AC16–AC20).
- The user always selects a route first, whether location is allowed or denied (F2b, AC21, AC23).
- Times per station = estimated schedule (AC24).
- "Affected" = a station that has backend incidents; banner counts stations (AC25).
- "Detail Berita" only on affected stations, together with TransJakarta stop chips (AC26).
- F3 changed from "stops within 1 km of the user" to "stops connected to the affected station"; AC13–AC15 rewritten; tapping a chip opens Apple Maps (AC27).
- News shows Green Line disruptions only.
- Selected route is not saved.
- Removed old open questions 1–3, 7 and 8 (tasks, not questions; 7 is answered in Constraints, 8 is in Notes for the Agent).
- Added Screens and States and Definition of Done.
- "Green Line" label on tab Berita is informational, not tappable.
- No "BARU" label; news time comes from the news itself.
- All news cards use one orange style (no grey cards).
- Route header ⚠️ appears when at least one station in the segment is affected.
- News relevance: latest news before a route is selected, segment news after (AC16, AC28).
- Removed the "delayed" / "normal" status label; AC10 and AC11 rewritten to use ⚠️ and the banner.
- Passed stations are faded; other station styles follow Apple HIG (AC3).
- Removed the chevron before the stop chips.
- States without a design use built-in iOS components.

### Changes suggested by the agent (review each one)
- Core loop step 1 (select route).
- News folded into F2 as F2a/F2b, to keep at most 3 MVP features.
- Tab names "Berita" / "Rute" and page titles.
- "Up to 3 latest incidents" on tab Berita (taken from the design).
- Empty search result text, AC22 (search filter).
- Test tags on every AC.
- Open questions 6, 12, 13, 14 and 15.- Notes about the README code and `///` doc comments.
