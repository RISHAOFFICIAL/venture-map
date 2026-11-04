import SwiftUI

/// Lays out three `OverviewMetric` tiles side by side. A small
/// "composition" view whose only job is to arrange other views.
struct ReachOverviewMetrics: View {
    let totalPeople: Int
    let eventCount: Int
    let neighborhoodCount: Int

    var body: some View {
        HStack(spacing: 10) {
            OverviewMetric(value: totalPeople.formatted(), title: "People reached")
            OverviewMetric(value: eventCount.formatted(), title: "Events")
            OverviewMetric(value: neighborhoodCount.formatted(), title: "Neighborhoods")
        }
        .padding(.vertical, 4)
    }
}
