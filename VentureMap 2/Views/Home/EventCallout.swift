import SwiftUI

/// The floating info card that appears above a map pin when it's tapped,
/// listing the most recent events at that location.
struct EventCallout: View {
    let cluster: LocationCluster
    let onSelectEvent: (CommunityEvent) -> Void
    let onShowAll: () -> Void
    let onDismiss: () -> Void

    // Computed on every read: take the cluster's events, newest first, and
    // keep at most 3. Because this is a computed property (not stored),
    // it's always in sync with `cluster.events` — there's nothing to
    // manually refresh.
    private var recentEvents: [CommunityEvent] {
        Array(cluster.events.sorted { $0.date > $1.date }.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    colors: [cluster.heatColor, cluster.heatColor.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 56)
                .overlay {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                }

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white, .black.opacity(0.4))
                }
                .padding(6)
                .accessibilityLabel("Close")
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(cluster.location)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(cluster.events.count) event\(cluster.events.count == 1 ? "" : "s") · \(cluster.totalPeopleReached) reached")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(recentEvents) { event in
                        Button {
                            onSelectEvent(event)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text(event.date, format: .dateTime.month(.abbreviated).day().year())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(event.peopleReached)")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.green)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                if cluster.events.count > recentEvents.count {
                    Button("View all \(cluster.events.count) events", action: onShowAll)
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding(14)
        }
        .frame(width: 260)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 14, y: 6)
        .transition(.scale(scale: 0.9, anchor: .bottom).combined(with: .opacity))
    }
}
