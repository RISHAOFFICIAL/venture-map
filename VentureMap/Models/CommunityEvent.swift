import SwiftUI
import MapKit

/// The central model of the whole app: one logged outreach event (a
/// workshop, listening session, or community event) at a specific place and
/// time. Almost every screen in VentureMap either displays, filters, creates,
/// or edits a list of these.
///
/// A few patterns worth studying here, since this is the most "complete"
/// model in the project:
/// - **Default property values** (`pointOfContact = ""`, `businessID =
///   Business.sampleBusinesses[0].id`) mean callers can omit those arguments
///   when constructing a `CommunityEvent`, as the sample data below does.
/// - **`static` sample data** (`sampleEvents`, `practiceEvents`) acts as a
///   stand-in for a real backend/database. Swapping these arrays for a
///   network call or persistence layer later wouldn't require changing any
///   view code, because views only ever see `[CommunityEvent]`.
/// - **`static func heatColor(forPeopleReached:)`** is a reusable, stateless
///   calculation — it doesn't need an instance of `CommunityEvent` to run, so
///   it's `static` rather than an instance method.
struct CommunityEvent: Identifiable {
    let id = UUID()
    var name: String
    var businessID = Business.sampleBusinesses[0].id
    var neighborhood: String
    var location: String
    var peopleReached: Int
    var category: EventCategory
    var eventType: EventType
    var date: Date
    var coordinate: CLLocationCoordinate2D
    var pointOfContact = ""
    var phoneNumber = ""
    var email = ""

    var heatColor: Color { Self.heatColor(forPeopleReached: peopleReached) }

    static func heatColor(forPeopleReached count: Int) -> Color {
        switch count {
        case 10...: .eventRed
        case 4...9: .eventOrange
        default: .eventYellow
        }
    }

    static let detroitRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.385, longitude: -83.08),
        span: MKCoordinateSpan(latitudeDelta: 0.20, longitudeDelta: 0.24)
    )

    // Hard-coded "fake database" of events for a signed-in account. Each one
    // is a `CommunityEvent(...)` built using named arguments — notice some
    // fields (like `pointOfContact`) are skipped because they have defaults
    // above.
    static let sampleEvents = [
        CommunityEvent(name: "Neighborhood Resource Fair", neighborhood: "Downtown", location: "Campus Martius", peopleReached: 18, category: .red, eventType: .communityEvent, date: .now.addingTimeInterval(-2 * 86_400), coordinate: CLLocationCoordinate2D(latitude: 42.3317, longitude: -83.0466)),
        CommunityEvent(name: "Digital Skills Workshop", neighborhood: "Midtown", location: "Detroit Public Library", peopleReached: 7, category: .orange, eventType: .workshop, date: .now.addingTimeInterval(-9 * 86_400), coordinate: CLLocationCoordinate2D(latitude: 42.3484, longitude: -83.0592)),
        CommunityEvent(name: "Corktown Listening Circle", neighborhood: "Corktown", location: "The Corner Ballpark", peopleReached: 3, category: .yellow, eventType: .listeningSession, date: .now.addingTimeInterval(-22 * 86_400), coordinate: CLLocationCoordinate2D(latitude: 42.3338, longitude: -83.0813)),
        CommunityEvent(name: "Market Day Outreach", neighborhood: "Eastern Market", location: "Eastern Market", peopleReached: 14, category: .red, eventType: .communityEvent, date: .now.addingTimeInterval(-43 * 86_400), coordinate: CLLocationCoordinate2D(latitude: 42.3489, longitude: -83.0408)),
        CommunityEvent(name: "Small Business Workshop", neighborhood: "Hamtramck", location: "Hamtramck Community Center", peopleReached: 6, category: .orange, eventType: .workshop, date: .now.addingTimeInterval(-61 * 86_400), coordinate: CLLocationCoordinate2D(latitude: 42.3928, longitude: -83.0496)),
        CommunityEvent(name: "Neighborhood Voices", neighborhood: "Southwest Detroit", location: "Clark Park", peopleReached: 2, category: .yellow, eventType: .listeningSession, date: .now.addingTimeInterval(-84 * 86_400), coordinate: CLLocationCoordinate2D(latitude: 42.3240, longitude: -83.0875)),
        CommunityEvent(name: "Summer Community Day", neighborhood: "Downtown", location: "Campus Martius", peopleReached: 11, category: .red, eventType: .communityEvent, date: .now.addingTimeInterval(-124 * 86_400), coordinate: CLLocationCoordinate2D(latitude: 42.3317, longitude: -83.0466)),
        CommunityEvent(name: "Career Readiness Workshop", neighborhood: "Warren", location: "Warren Civic Center", peopleReached: 5, category: .orange, eventType: .workshop, date: .now.addingTimeInterval(-181 * 86_400), coordinate: CLLocationCoordinate2D(latitude: 42.5145, longitude: -83.0147)),
        CommunityEvent(name: "Family Feedback Session", neighborhood: "Dearborn", location: "Ford Community Center", peopleReached: 4, category: .yellow, eventType: .listeningSession, date: .now.addingTimeInterval(-252 * 86_400), coordinate: CLLocationCoordinate2D(latitude: 42.3223, longitude: -83.1763))
    ]

    static var nextCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: 42.355, longitude: -83.065)
    }

    // A small, obviously-fake dataset for guests — distinct from sampleEvents
    // so practice mode never shows what a signed-in account actually sees.
    static let practiceEvents = [
        CommunityEvent(
            name: "Practice: Neighborhood Meetup",
            businessID: Business.practiceBusinesses[0].id,
            neighborhood: "Sample Downtown",
            location: "Practice Plaza",
            peopleReached: 12,
            category: .red,
            eventType: .communityEvent,
            date: .now.addingTimeInterval(-3 * 86_400),
            coordinate: CLLocationCoordinate2D(latitude: 42.3317, longitude: -83.0466)
        ),
        CommunityEvent(
            name: "Practice: Skills Workshop",
            businessID: Business.practiceBusinesses[0].id,
            neighborhood: "Sample Midtown",
            location: "Practice Library",
            peopleReached: 6,
            category: .orange,
            eventType: .workshop,
            date: .now.addingTimeInterval(-10 * 86_400),
            coordinate: CLLocationCoordinate2D(latitude: 42.3484, longitude: -83.0592)
        ),
        CommunityEvent(
            name: "Practice: Listening Session",
            businessID: Business.practiceBusinesses[0].id,
            neighborhood: "Sample Corktown",
            location: "Practice Community Hall",
            peopleReached: 2,
            category: .yellow,
            eventType: .listeningSession,
            date: .now.addingTimeInterval(-18 * 86_400),
            coordinate: CLLocationCoordinate2D(latitude: 42.3338, longitude: -83.0813)
        )
    ]
}
