import SwiftUI

/// One row in the "Top spots" list on `ReachOverviewView`, built from a
/// derived `LocationSummary` rather than a raw `CommunityEvent`.
struct TopLocationRow: View {
    let location: LocationSummary

    var body: some View {
        HStack {
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 3) {
                Text(location.location)
                    .font(.body.weight(.semibold))
                Text("\(location.eventsCount) events")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(location.peopleReached) reached")
                .font(.subheadline.weight(.semibold))
        }
    }
}
