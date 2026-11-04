import SwiftUI

/// The full-screen "Reach overview" sheet, opened by tapping `ReachCard`.
/// Shows totals, a ranked list of top locations, and a couple of simple
/// data-driven insights.
///
/// - **`@Environment(\.dismiss)`** reads a dismiss action from the
///   environment rather than being passed an explicit closure — SwiftUI
///   automatically provides this for any view presented via `.sheet`, so the
///   view can close itself without its parent wiring up an `onDismiss`
///   closure by hand.
/// - **`NavigationStack` + `NavigationLink`**: tapping a `TopLocationRow`
///   pushes `LocationEventsView` onto a navigation stack *inside* this sheet
///   — a totally independent stack from whatever navigation exists on the
///   rest of the app.
/// - **`topLocations`** is a computed property built with `Dictionary(grouping:by:)`
///   (grouping events by location name) followed by `.map` (turning each
///   group into a `LocationSummary`) and `.sorted` (ranking by people
///   reached, then event count) — a good example of chaining several
///   higher-order functions to turn raw data into exactly the shape a view
///   needs.
struct ReachOverviewView: View {
    @Environment(\.dismiss) private var dismiss

    let events: [CommunityEvent]
    let onUpdateEvent: (CommunityEvent) -> Void

    private var totalPeople: Int {
        events.reduce(0) { $0 + $1.peopleReached }
    }

    private var topLocations: [LocationSummary] {
        Dictionary(grouping: events, by: \.location)
            .map { location, events in
                LocationSummary(
                    location: location,
                    eventsCount: events.count,
                    peopleReached: events.reduce(0) { $0 + $1.peopleReached }
                )
            }
            .sorted {
                $0.peopleReached == $1.peopleReached
                    ? $0.eventsCount > $1.eventsCount
                    : $0.peopleReached > $1.peopleReached
            }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ReachOverviewMetrics(
                        totalPeople: totalPeople,
                        eventCount: events.count,
                        neighborhoodCount: Set(events.map(\.neighborhood)).count
                    )
                }

                Section("Top spots") {
                    ForEach(topLocations) { location in
                        NavigationLink {
                            LocationEventsView(
                                location: location.location,
                                events: events.filter { $0.location == location.location },
                                onUpdateEvent: onUpdateEvent
                            )
                        } label: {
                            TopLocationRow(location: location)
                        }
                    }
                }

                Section("What the data says") {
                    Label("\(topLocations.first?.location ?? "Your community") is your highest-reach location.", systemImage: "mappin.and.ellipse")
                    Label("\(events.count) events have been imported to your map.", systemImage: "arrow.down.doc")
                }
            }
            .navigationTitle("Reach overview")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Exit overview")
                }
            }
        }
    }
}
