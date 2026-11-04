/// The things a guest can try from the profile's "What you can do" list.
/// Tapping a row reports one of these, and `VentureMapHomeView` takes the
/// guest to the matching part of the app.
enum GuestFeature {
    case exploreMap
    case addEvent
    case checkReach
    case saveProgress
}
