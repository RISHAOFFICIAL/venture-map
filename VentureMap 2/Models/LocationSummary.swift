/// A rolled-up stat line for one location, used by `ReachOverviewView` to
/// show "top spots" — e.g. "Campus Martius · 14 reached".
///
/// This type doesn't come from anywhere permanent; it's *derived* data,
/// computed on the fly from a list of `CommunityEvent`s (see
/// `ReachOverviewView.topLocations`). Modeling derived data as its own small
/// struct — rather than passing raw tuples or dictionaries around — makes
/// the rest of the view code read much more clearly.
struct LocationSummary: Identifiable {
    var id: String { location }
    let location: String
    let eventsCount: Int
    let peopleReached: Int
}
