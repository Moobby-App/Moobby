//
//  TravelSchedule.swift
//  moobby
//
//  Iteration 2: estimated time at each station of the user's segment.
//

import Foundation

/// How the app estimates when the user reaches each station, read from `schedule.json`.
///
/// > Note: Placeholder for the prototype. There's no real KRL schedule yet (SPEC open question 9), so every
/// > station is ``minutesBetweenStations`` after the previous one, counting from when the user departs.
struct TravelSchedule: Decodable, Hashable {
    /// Estimated minutes from one station to the next.
    let minutesBetweenStations: Int

    /// The estimated time at each station in `segment`, keyed by ``GreenLineStation/id``.
    ///
    /// The first station is `departure`; each next one adds ``minutesBetweenStations``.
    ///
    /// Covers AC24.
    func estimatedTimes(for segment: [GreenLineStation], departingAt departure: Date) -> [String: Date] {
        var times: [String: Date] = [:]
        for (index, station) in segment.enumerated() {
            let minutes = index * minutesBetweenStations
            times[station.id] = departure.addingTimeInterval(TimeInterval(minutes * 60))
        }
        return times
    }
}
