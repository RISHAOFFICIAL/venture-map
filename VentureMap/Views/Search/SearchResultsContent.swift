import SwiftUI

/// The matching-events list shown by `LocationSearchView` once the search
/// query has at least one match.
struct SearchResultsContent: View {
    let events: [CommunityEvent]
    let onSelectEvent: (CommunityEvent) -> Void

    var body: some View {
        List {
            Section("\(events.count) results") {
                ForEach(events) { event in
                    Button {
                        onSelectEvent(event)
                    } label: {
                        HStack(spacing: 11) {
                            EventMarker(count: event.peopleReached, color: event.heatColor)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(event.location)
                                    .font(.subheadline.weight(.semibold))
                                Text("\(event.neighborhood) · 1 event")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
