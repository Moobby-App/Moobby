#!/usr/bin/env python3
"""Generates moobby/Core/Model/GreenLineTrack.swift from OpenStreetMap.

Downloads the KRL Lin Rangkasbitung route (OSM relation 15094546, Tanah Abang → Rangkasbitung),
joins its track segments into one line, and drops points that sit within 8 m of the simplified line.

    python3 scripts/green_line_track.py            # download from Overpass
    python3 scripts/green_line_track.py rk.json    # reuse a saved Overpass response

Map data © OpenStreetMap contributors, available under the ODbL.
"""
import datetime, getpass, json, math, re, subprocess, sys
from pathlib import Path

RELATION = 15094546
TOLERANCE_METERS = 8
ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "moobby/Core/Model/GreenLineTrack.swift"

def meters(a, b):
    # Equirectangular is accurate to well under 1 m at these distances.
    lat = math.radians((a[0] + b[0]) / 2)
    dx = math.radians(b[1] - a[1]) * math.cos(lat) * 6371000
    dy = math.radians(b[0] - a[0]) * 6371000
    return math.hypot(dx, dy)

def stitch(ways):
    """Joins ordered OSM ways into one line, flipping each way so its start meets the previous end."""
    line = list(ways[0])
    if len(ways) > 1 and min(meters(line[0], ways[1][0]), meters(line[0], ways[1][-1])) < \
       min(meters(line[-1], ways[1][0]), meters(line[-1], ways[1][-1])):
        line.reverse()
    gaps = []
    for w in ways[1:]:
        if meters(line[-1], w[-1]) < meters(line[-1], w[0]):
            w = list(reversed(w))
        gap = meters(line[-1], w[0])
        if gap > 1: gaps.append(round(gap))
        line += w[1:] if gap < 1 else w
    return line, gaps

def point_segment(p, a, b):
    # Distance from p to segment ab, in a local flat projection around p.
    lat = math.radians(p[0]); k = 111320
    ax, ay = (a[1]-p[1])*k*math.cos(lat), (a[0]-p[0])*k
    bx, by = (b[1]-p[1])*k*math.cos(lat), (b[0]-p[0])*k
    dx, dy = bx-ax, by-ay
    t = 0 if dx == dy == 0 else max(0, min(1, -(ax*dx+ay*dy)/(dx*dx+dy*dy)))
    return math.hypot(ax+t*dx, ay+t*dy)

def simplify(pts, tol):
    """Douglas–Peucker: drops points that sit within `tol` meters of the line between their neighbours."""
    if len(pts) < 3: return pts
    keep = [False]*len(pts); keep[0] = keep[-1] = True
    stack = [(0, len(pts)-1)]
    while stack:
        i, j = stack.pop()
        best, idx = 0, None
        for k in range(i+1, j):
            d = point_segment(pts[k], pts[i], pts[j])
            if d > best: best, idx = d, k
        if idx is not None and best > tol:
            keep[idx] = True; stack += [(i, idx), (idx, j)]
    return [p for p, k in zip(pts, keep) if k]

def distance_to_line(p, line):
    return min(point_segment(p, line[i], line[i+1]) for i in range(len(line)-1))


def run(*args):
    """Output of a command, or "" if it fails or isn't installed."""
    try:
        return subprocess.run(args, capture_output=True, text=True).stdout.strip()
    except OSError:
        return ""

def author():
    """The name Xcode puts in "Created by": the macOS account's full name, then git's, then the login."""
    return run("id", "-F") or run("git", "config", "user.name") or getpass.getuser()

def team():
    """The signing team from project.yml, as "Name (ID)" when this Mac has a certificate for it."""
    match = re.search(r"DEVELOPMENT_TEAM:\s*(\w+)", (ROOT / "project.yml").read_text())
    if not match:
        return None
    team_id = match.group(1)
    # A signing certificate's subject has the team ID as OU and the team name as O.
    pems = re.findall(r"-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----",
                      run("security", "find-certificate", "-a", "-c", "Apple", "-p"), re.S)
    for pem in pems:
        subject = subprocess.run(["openssl", "x509", "-noout", "-subject", "-nameopt", "multiline,utf8"],
                                 input=pem, capture_output=True, text=True).stdout
        fields = dict(re.findall(r"^\s+(\w+)\s+= (.*)$", subject, re.M))
        if fields.get("organizationalUnitName") == team_id and fields.get("organizationName"):
            return f"{fields['organizationName']} ({team_id})"
    return team_id

def download():
    query = f"[out:json][timeout:90];relation({RELATION});out geom;"
    # curl, not urllib: the python3 bundled with Xcode links LibreSSL 2.8.3, which Overpass's TLS rejects.
    result = subprocess.run(
        ["curl", "--silent", "--show-error", "--fail", "--max-time", "150",
         # Overpass rejects requests without a descriptive User-Agent.
         "--user-agent", "Moobby/1.0 (green line track export)", "--header", "Accept: application/json",
         "--data-urlencode", f"data={query}", "https://overpass-api.de/api/interpreter"],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        sys.exit(f"Download failed: {result.stderr.strip()}\nOverpass is often busy; wait a minute and try again.")
    return json.loads(result.stdout)

def main():
    data = json.load(open(sys.argv[1])) if len(sys.argv) > 1 else download()
    rel = data["elements"][0]
    ways = [[(g["lat"], g["lon"]) for g in m["geometry"]] for m in rel["members"] if m["type"] == "way"]
    stops = [(m["lat"], m["lon"]) for m in rel["members"] if m["type"] == "node"]

    line, gaps = stitch(ways)
    track = simplify(line, TOLERANCE_METERS)

    # The line must be continuous, run Tanah Abang → Rangkasbitung, and pass every stop.
    assert not gaps, f"track has gaps of {gaps} m; the relation's ways may be out of order"
    assert meters(track[0], stops[0]) < 500 and meters(track[-1], stops[-1]) < 500, "endpoints don't match the stops"
    assert max(distance_to_line(s, track) for s in stops) < 60, "a stop is more than 60 m from the track"

    # Same "Created by" line Xcode writes, for whoever ran the script.
    signature = f"//  Created by {author()} on {datetime.date.today():%d/%m/%y}.\n"
    if signing_team := team():
        signature += f"//  Team: {signing_team}\n"

    points = ",\n".join(f"        CLLocationCoordinate2D(latitude: {la:.6f}, longitude: {lo:.6f})" for la, lo in track)
    OUTPUT.write_text(f"""//
//  GreenLineTrack.swift
//  moobby
//
{signature}//
//  Generated by scripts/green_line_track.py. Don't edit by hand; re-run the script instead.
//  Map data © OpenStreetMap contributors, available under the ODbL (openstreetmap.org/copyright).
//

import CoreLocation

/// The KRL Green Line's real track, Tanah Abang to Rangkasbitung, for drawing the line on the map.
///
/// Draw it with a `MapPolyline`; it bends with the rails, unlike straight lines between
/// ``GreenLineStation/all``:
///
/// ```swift
/// MapPolyline(coordinates: GreenLineTrack.coordinates)
///     .stroke(.green, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
/// ```
///
/// Traced from [OpenStreetMap relation {RELATION}](https://www.openstreetmap.org/relation/{RELATION})
/// and simplified to within {TOLERANCE_METERS} m of the full track.
///
/// > Important: Showing it requires crediting OpenStreetMap. ``MapView`` does this with a
/// > "Track © OpenStreetMap contributors" link under the Green Line header; keep it wherever the track appears.
///
/// This file is generated. To update the track, run `python3 scripts/green_line_track.py` from the project
/// root instead of editing it; hand edits are lost the next time the script runs.
enum GreenLineTrack {{
    /// The track's {len(track)} points, in order from Tanah Abang to Rangkasbitung.
    static let coordinates: [CLLocationCoordinate2D] = [
{points}
    ]
}}
""")
    print(f"Wrote {len(track)} points to {OUTPUT}")

if __name__ == "__main__":
    main()
