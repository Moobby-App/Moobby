//
//  NewsCard.swift
//  moobby
//
//  Iteration 2: one news card on tab Berita.
//

import SwiftUI

/// One disruption on tab Berita: title, short description and time, on an orange card (Decision 8).
/// The chevron shows it opens Detail Berita.
///
/// Covers AC16 (title, description and news time on each card).
struct NewsCard: View {
    let incident: Incident

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(incident.title)
                    .bold()
                    .typography(.body)
                    .foregroundStyle(.primary)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }

            if let description = incident.cardDescription {
                Text(description)
                    .typography(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(incident.cardFooter)
                .typography(.caption)
                .foregroundStyle(.orange)
        }
        .padding(.trailing, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .trailing) {
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.orange.opacity(0.15), in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

extension Incident {

    /// The card's second line: ``summary`` when the backend sends one, otherwise ``locationName``.
    ///
    /// The backend has no description field yet (SPEC open question 1).
    var cardDescription: String? {
        summary ?? locationName
    }

    /// The card's last line, such as `"Gangguan layanan · 18 Okt, 11.20"`.
    var cardFooter: String {
        guard let date = publishedDate else { return categoryLabel }
        let time = date.formatted(
            .dateTime.day().month(.abbreviated).hour().minute().locale(Locale(identifier: "id_ID"))
        )
        return "\(categoryLabel) · \(time)"
    }

    /// ``category`` in Indonesian. Unknown values show as "Info" instead of the raw code.
    var categoryLabel: String {
        switch category {
        case "service_disruption": "Gangguan layanan"
        case "incident": "Kejadian sekitar stasiun"
        default: "Info"
        }
    }
}

#if DEBUG
#Preview {
    VStack {
        ForEach(Incident.previewSamples.prefix(2)) { NewsCard(incident: $0) }
    }
    .padding()
}
#endif
