import SwiftUI

/// The floating stats card pinned to the bottom of the map, showing a quick
/// summary and legend. Tapping it (handled by the parent — see
/// `VentureMapHomeView`, which wraps this in a `Button`) opens the full
/// `ReachOverviewView`.
struct ReachCard: View {
    let events: [CommunityEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your reach")
                .font(.headline)
            // `Set(events.map(\.neighborhood)).count` turns the event list
            // into just its neighborhood names, then a `Set` automatically
            // drops duplicates — a quick way to count "how many distinct
            // neighborhoods" without writing a loop.
            Text("\(events.count) events across \(Set(events.map(\.neighborhood)).count) neighborhoods")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))

            HStack(spacing: 16) {
                ReachLegend(color: .eventRed, title: "10+ reached")
                ReachLegend(color: .eventOrange, title: "4–9 reached")
                ReachLegend(color: .eventYellow, title: "1–3 reached")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        .background(Color.black.opacity(0.84), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
