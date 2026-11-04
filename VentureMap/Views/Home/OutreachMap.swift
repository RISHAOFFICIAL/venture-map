import SwiftUI
import MapKit

/// Wraps Apple's `Map` view with VentureMap's custom pins and callout.
///
/// Key MapKit + SwiftUI concepts here:
/// - **`MapCameraPosition`** (held outside this view, passed in via
///   `@Binding`) is what the map is currently looking at — this view can
///   read it, but also *change* it (e.g. when a marker is selected), and
///   that change flows back up to whoever owns the real `@State`.
/// - **`MapReader`** gives you a `proxy` that can convert a map coordinate
///   into on-screen (x, y) points — used below to position the floating
///   `EventCallout` directly above the selected pin.
/// - **`Map { ... }`** takes map *content* as a view builder, similar to how
///   `VStack { ... }` takes its children — `UserAnnotation()` and each
///   `Annotation` are map content, not regular views.
struct OutreachMap: View {
    let events: [CommunityEvent]
    @Binding var cameraPosition: MapCameraPosition
    @Binding var selectedLocation: SelectedLocation?
    let onSelectEvent: (CommunityEvent) -> Void
    let onShowAllEvents: (SelectedLocation) -> Void

    // Groups events at the same location into a single marker so overlapping
    // points of interest don't stack illegibly on top of each other, per HIG.
    private var locationClusters: [LocationCluster] {
        Dictionary(grouping: events, by: \.location)
            .map { location, events in
                LocationCluster(location: location, coordinate: events[0].coordinate, events: events)
            }
    }

    private var selectedCluster: LocationCluster? {
        guard let selectedLocation else { return nil }
        return locationClusters.first { $0.location == selectedLocation.location }
    }

    var body: some View {
        MapReader { proxy in
            Map(position: $cameraPosition) {
                UserAnnotation()

                ForEach(locationClusters) { cluster in
                    let isSelected = selectedLocation?.location == cluster.location

                    Annotation(cluster.location, coordinate: cluster.coordinate) {
                        Button {
                            withAnimation(.snappy) {
                                selectedLocation = isSelected ? nil : SelectedLocation(location: cluster.location)
                            }
                        } label: {
                            EventMarker(
                                count: cluster.totalPeopleReached,
                                color: cluster.heatColor,
                                clusterCount: cluster.events.count > 1 ? cluster.events.count : nil,
                                isSelected: isSelected
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            cluster.events.count > 1
                                ? "\(cluster.events.count) events reaching \(cluster.totalPeopleReached) people at \(cluster.location)"
                                : "\(cluster.totalPeopleReached) people reached at \(cluster.location)"
                        )
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic, emphasis: .muted))
            .overlay {
                // Drawing the callout as an overlay above the whole Map — rather than
                // as map content alongside the pins — guarantees it's always rendered
                // in front of every marker, instead of competing with MapKit's own
                // internal annotation stacking order.
                if let selectedCluster, let point = proxy.convert(selectedCluster.coordinate, to: .local) {
                    EventCallout(
                        cluster: selectedCluster,
                        onSelectEvent: onSelectEvent,
                        onShowAll: { onShowAllEvents(SelectedLocation(location: selectedCluster.location)) },
                        onDismiss: { selectedLocation = nil }
                    )
                    .position(x: point.x, y: point.y - 150)
                    .transition(.scale(scale: 0.9, anchor: .bottom).combined(with: .opacity))
                }
            }
        }
    }
}
