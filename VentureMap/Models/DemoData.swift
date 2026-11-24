/// One switch for the sample data in the app.
///
/// VentureMap shipped to class with ready-made sample businesses and
/// events so the map was never empty — good for a demo, wrong for real
/// users, who should start with their own blank map and add their own
/// businesses and events. This flag is the single place that decides
/// which one the app does:
///
/// - `false` (shipping): a signed-in account starts with no businesses
///   and no events. The home screen, the tour, and the reach overview
///   all handle the empty map, and the first thing the app asks for is
///   the user's own business.
/// - `true` (class demo / promo recording): a signed-in account starts
///   with the VentureMap Tech and VentureMap Labs businesses and the
///   nine sample events, exactly like the class build did.
///
/// Guests are not affected either way: practice mode always uses the
/// clearly labeled practice business and practice events.
///
/// Flip this one line to switch modes. Nothing else in the app checks
/// sample data directly — `VentureMapHomeView` (businesses and event
/// seeding) and `VentureMapTourManager` (tour copy) both read this flag.
enum DemoData {
    static let isEnabled = false
}
