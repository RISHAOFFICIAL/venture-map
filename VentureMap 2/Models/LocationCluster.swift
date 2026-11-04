import SwiftUI
import MapKit

/// Groups every `CommunityEvent` that happened at the same location into one
/// map pin, so that ten events at the same address don't draw ten
/// overlapping markers. Built in `OutreachMap.locationClusters`.
struct LocationCluster: Identifiable {
    let location: String
    let coordinate: CLLocationCoordinate2D
    let events: [CommunityEvent]

    var id: String { location }

    // Computed properties can be as simple or as involved as they need to
    // be. `totalPeopleReached` folds (reduces) the whole `events` array down
    // to a single number using `reduce(0) { ... }` — a very common
    // functional-programming pattern for "sum up a property across a list."
    var totalPeopleReached: Int { events.reduce(0) { $0 + $1.peopleReached } }

    // Delegates to a `static` helper on `CommunityEvent` so the "what color
    // counts as what" logic lives in exactly one place.
    var heatColor: Color { CommunityEvent.heatColor(forPeopleReached: totalPeopleReached) }
}
