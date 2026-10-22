//
//  NewsRoute.swift
//  moobby
//
//  Iteration 2: where tab Berita can navigate.
//

import Foundation

/// The screens tab Berita pushes onto its `NavigationStack` (team convention: a `Hashable` route enum
/// with `navigationDestination(for:)`).
enum NewsRoute: Hashable {
    /// Semua Berita: every Green Line incident (AC17).
    case allNews
    /// Detail Berita for one incident (AC18).
    case detail(Incident)
}
