//
//  RouteStatusLogicTests.swift
//  moobbyTests
//
//  Created by Maula Izza Azizi on 19/10/26.
//

import XCTest
@testable import moobby

@MainActor
final class RouteStatusLogicTests: XCTestCase {
    private let greenLeg = ["RU", "SDM", "JMU", "PDJ", "KBY", "PLM", "THB"]
    private let samples = CorridorIncident.curatedSamples

    // MARK: - Status

    func testGreenLegIsDisruptedBySudimara() {
        let report = RouteStatusLogic.report(forLeg: greenLeg, incidents: samples)
        XCTAssertEqual(report.status, .disrupted)
        XCTAssertEqual(report.main?.id, "inc-001")
    }

    func testOtherReportsAreListedMostSevereThenNearestFirst() {
        let report = RouteStatusLogic.report(forLeg: greenLeg, incidents: samples)
        // Both are caution; Kebayoran (0.31 km) is nearer than Palmerah (0.48 km).
        XCTAssertEqual(report.others.map(\.id), ["inc-003", "inc-002"])
    }

    func testIncidentOffTheRouteIsIgnored() {
        let report = RouteStatusLogic.report(forLeg: greenLeg, incidents: samples)
        let ids = ([report.main].compactMap { $0 } + report.others).map(\.id)
        XCTAssertFalse(ids.contains("inc-004"))
    }

    func testLegWithoutReportsIsClear() {
        let report = RouteStatusLogic.report(forLeg: ["SRP"], incidents: samples)
        XCTAssertEqual(report, LegReport(status: .clear, main: nil, others: []))
    }

    // MARK: - Route

    func testRouteTowardTanahAbang() throws {
        let rawaBuntu = try station("RU"), tanahAbang = try station("THB")
        let steps = RouteStep.route(from: rawaBuntu, to: tanahAbang, walkMeters: 213)

        XCTAssertEqual(steps.first, .walk(distanceMeters: 213))
        XCTAssertEqual(steps[1], .station(role: .departure, station: rawaBuntu))
        guard case .leg(let stations, _) = steps[2] else { return XCTFail("Expected a leg") }
        XCTAssertEqual(stations.map(\.id), greenLeg)
        XCTAssertEqual(steps.last, .station(role: .arrival, station: tanahAbang))
    }

    func testRouteTowardRangkasbitungWithoutWalk() throws {
        let steps = RouteStep.route(from: try station("KBY"), to: try station("SRP"))
        XCTAssertEqual(steps.count, 3)
        guard case .leg(let stations, _) = steps[1] else { return XCTFail("Expected a leg") }
        XCTAssertEqual(stations.map(\.id), ["KBY", "PDJ", "JMU", "SDM", "RU", "SRP"])
    }

    func testRouteToSameStationIsEmpty() throws {
        XCTAssertTrue(RouteStep.route(from: try station("RU"), to: try station("RU")).isEmpty)
    }

    func testNearestStation() throws {
        // Terminal Angkot Sudimara (tr-07), about 80 m from Stasiun Sudimara.
        let nearest = try XCTUnwrap(RouteStatusLogic.nearestStation(to: NearbyTransitPoint.catalog[6].coordinate))
        XCTAssertEqual(nearest.station.id, "SDM")
        XCTAssertLessThan(nearest.meters, 150)
    }

    func testUnverifiedServiceDisruptionIsOnlyCaution() {
        let incident = makeIncident(category: "service_disruption", distanceKm: 0.2, verified: false)
        XCTAssertEqual(RouteStatusLogic.status(of: incident), .caution)
    }

    func testCautionStopsAtOneKilometer() {
        XCTAssertEqual(RouteStatusLogic.status(of: makeIncident(distanceKm: 1.0)), .caution)
        XCTAssertEqual(RouteStatusLogic.status(of: makeIncident(distanceKm: 1.2)), .clear)

        let report = RouteStatusLogic.report(forLeg: ["SDM"], incidents: [makeIncident(distanceKm: 1.2)])
        XCTAssertEqual(report.status, .clear)
        XCTAssertNil(report.main)
    }

    func testSeverityOrder() {
        XCTAssertTrue(LegStatus.disrupted > .caution)
        XCTAssertTrue(LegStatus.caution > .clear)
    }

    // MARK: - Expanded leg rows

    func testExpandedRowsPutEachMarkerAfterItsStation() throws {
        let rows = RouteStatusLogic.timelineRows(stations: try legStations(), incidents: samples)
        XCTAssertEqual(rows.map(\.id), [
            "station-RU", "station-SDM", "incident-inc-001", "station-JMU", "station-PDJ",
            "station-KBY", "incident-inc-003", "station-PLM", "incident-inc-002", "station-THB"
        ])
        guard case .incident(_, _, let after, let before) = rows[6] else { return XCTFail("Expected a marker") }
        XCTAssertEqual([after.id, before.id], ["KBY", "PLM"])
        guard case .station(_, let number) = rows[1] else { return XCTFail("Expected a station") }
        XCTAssertEqual(number, 2)
    }

    func testMarkerAtLastStationGoesBeforeIt() throws {
        let rows = RouteStatusLogic.timelineRows(stations: try legStations(), incidents: [makeIncident(stationId: "THB", distanceKm: 0.2)])
        XCTAssertEqual(rows.suffix(3).map(\.id), ["station-PLM", "incident-test", "station-THB"])
    }

    func testIncidentsAtOneStationShareAMarker() throws {
        let incidents = [
            makeIncident(id: "a", distanceKm: 0.5),
            makeIncident(id: "b", category: "service_disruption", distanceKm: 0.9, verified: true)
        ]
        let markers = RouteStatusLogic.timelineRows(stations: try legStations(), incidents: incidents).compactMap { row -> (String, [String])? in
            guard case .incident(let main, let others, _, _) = row else { return nil }
            return (main.id, others.map(\.id))
        }
        XCTAssertEqual(markers.count, 1)
        XCTAssertEqual(markers.first?.0, "b")
        XCTAssertEqual(markers.first?.1, ["a"])
    }

    func testOffRouteIncidentHasNoMarker() throws {
        let rows = RouteStatusLogic.timelineRows(stations: try legStations(), incidents: samples)
        XCTAssertFalse(rows.contains { $0.id == "incident-inc-004" })
    }

    func testCategoryLabels() {
        XCTAssertEqual(RouteStatusLogic.categoryLabel("service_disruption"), "Gangguan Layanan")
        XCTAssertEqual(RouteStatusLogic.categoryLabel("incident"), "Kecelakaan")
    }

    // MARK: - Alternatives

    func testAlternativesNearSudimara() throws {
        let sudimara = try XCTUnwrap(samples.first { $0.id == "inc-001" })
        let alternatives = RouteStatusLogic.alternatives(for: sudimara, model: MapViewModel())
        let ids = alternatives.map(\.id)

        XCTAssertTrue(ids.contains("tr-07"))
        XCTAssertTrue(ids.contains("tr-06"))
        XCTAssertFalse(ids.contains { $0.hasPrefix("krl-") })
        XCTAssertLessThanOrEqual(alternatives.count, RouteStatusLogic.maxAlternatives)

        let distances = alternatives.compactMap(\.straightLineDistanceKm)
        XCTAssertEqual(distances, distances.sorted())
        XCTAssertTrue(distances.allSatisfy { $0 <= RouteStatusLogic.alternativeRadiusKm })
    }

    func testAlternativesStayNearTheirOwnStation() throws {
        let kebayoran = try XCTUnwrap(samples.first { $0.id == "inc-003" })
        let ids = RouteStatusLogic.alternatives(for: kebayoran, model: MapViewModel()).map(\.id)
        // Halte Velbak and Pasar Kebayoran Lama are by Kebayoran; Halte Stasiun Palmerah (tr-02) is ~3.4 km away.
        XCTAssertTrue(ids.contains("tr-03"))
        XCTAssertTrue(ids.contains("tr-04"))
        XCTAssertFalse(ids.contains("tr-02"))
    }

    func testFilterDropsFarPointsAndKeepsTopThree() {
        let points = [3.0, 0.5, 2.4, 0.1, 1.0].enumerated().map { index, km in
            makeTransit(id: "tr-\(index)", mode: "TransJakarta", km: km)
        }
        let kept = RouteStatusLogic.filterAlternatives(points)
        XCTAssertEqual(kept.map(\.straightLineDistanceKm), [0.1, 0.5, 1.0])
    }

    func testFilterExcludesGreenLineStations() {
        let station = makeTransit(id: "krl-SDM", mode: "KRL Green Line", km: 0.1)
        XCTAssertTrue(RouteStatusLogic.filterAlternatives([station]).isEmpty)
    }

    func testModeSymbols() {
        XCTAssertEqual(RouteStatusLogic.symbol(forMode: "TransJakarta"), "bus.fill")
        XCTAssertEqual(RouteStatusLogic.symbol(forMode: "MRT Jakarta"), "tram.fill")
        XCTAssertEqual(RouteStatusLogic.symbol(forMode: "Shuttle Bus"), "bus")
        XCTAssertEqual(RouteStatusLogic.symbol(forMode: "BSD Link / Bus"), "bus")
        XCTAssertEqual(RouteStatusLogic.symbol(forMode: "Angkot / Feeder"), "car.fill")
        XCTAssertEqual(RouteStatusLogic.symbol(forMode: "KRL Green Line"), "tram.fill")
        XCTAssertEqual(RouteStatusLogic.symbol(forMode: "Ojek"), "mappin.circle.fill")
    }

    func testDistanceLabel() {
        XCTAssertEqual(RouteStatusLogic.distanceLabel(km: 0.42), "± 0.4 km (garis lurus)")
    }

    // MARK: - Helpers

    private func station(_ id: String) throws -> GreenLineStation {
        try XCTUnwrap(GreenLineStation.all.first { $0.id == id })
    }

    private func legStations() throws -> [GreenLineStation] {
        guard case .leg(let stations, _) = RouteStep.route(from: try station("RU"), to: try station("THB"))[1] else {
            throw XCTSkip("Expected a leg")
        }
        return stations
    }

    private func makeIncident(
        id: String = "test", category: String = "incident", stationId: String = "SDM", distanceKm: Double, verified: Bool = false
    ) -> CorridorIncident {
        CorridorIncident(
            id: id, title: "Test", category: category, locationName: "Test",
            latitude: -6.2966, longitude: 106.7126, nearestStationId: stationId, nearestStationName: "Test",
            distanceToStationKm: distanceKm, publishedAt: "", sourceName: "",
            verificationStatus: verified ? "verified" : "unverified"
        )
    }

    private func makeTransit(id: String, mode: String, km: Double) -> NearbyTransitPoint {
        NearbyTransitPoint(id: id, name: id, mode: mode, routesInfo: "", latitude: 0, longitude: 0, straightLineDistanceKm: km)
    }
}
