import SwiftUI
import MapKit
import SwiftData

/// The central model of the whole app: one logged outreach event (a
/// workshop, listening session, or community event) at a specific place and
/// time. Almost every screen in VentureMap either displays, filters, creates,
/// or edits a list of these.
///
/// This is a SwiftData model (`@Model`), so events are saved on the device
/// and survive app relaunches. A few patterns worth studying here, since
/// this is the most "complete" model in the project:
/// - **Default property values** (`pointOfContact = ""`, `businessID =
///   Business.sampleBusinesses[0].id`) mean callers can omit those arguments
///   when constructing a `CommunityEvent`, as the sample data below does.
/// - **`static` sample data** (`sampleEvents`, `practiceEvents`) seeds the
///   store on first launch for a signed-in account. Guests never touch the
///   saved store: `practiceEvents` stays in memory only.
/// - **Coordinates are stored as latitude/longitude**, because SwiftData
///   cannot persist `CLLocationCoordinate2D` directly. The computed
///   `coordinate` property keeps the rest of the app reading and writing
///   coordinates exactly as before.
/// - **`static func heatColor(forPeopleReached:)`** is a reusable, stateless
///   calculation — it doesn't need an instance of `CommunityEvent` to run, so
///   it's `static` rather than an instance method.
/// - **Editing works on a detached copy** (`detachedCopy()`): edit sheets
///   change the copy, and only `update(from:)` writes those changes onto the
///   saved event when the user confirms. Cancelling never touches the store.
@Model
final class CommunityEvent {
    var id: UUID = UUID()
    var name: String
    var businessID: UUID
    var neighborhood: String
    var location: String
    var peopleReached: Int
    var category: EventCategory
    var eventType: EventType
    var date: Date
    var latitude: Double
    var longitude: Double
    var pointOfContact: String
    var phoneNumber: String
    var email: String

    /// The map coordinate for this event, backed by the stored
    /// `latitude`/`longitude` pair.
    var coordinate: CLLocationCoordinate2D {
        get { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }

    var heatColor: Color { Self.heatColor(forPeopleReached: peopleReached) }

    init(
        id: UUID = UUID(),
        name: String,
        businessID: UUID = Business.sampleBusinesses[0].id,
        neighborhood: String,
        location: String,
        peopleReached: Int,
        category: EventCategory,
        eventType: EventType,
        date: Date,
        coordinate: CLLocationCoordinate2D,
        pointOfContact: String = "",
        phoneNumber: String = "",
        email: String = ""
    ) {
        self.id = id
        self.name = name
        self.businessID = businessID
        self.neighborhood = neighborhood
        self.location = location
        self.peopleReached = peopleReached
        self.category = category
        self.eventType = eventType
        self.date = date
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.pointOfContact = pointOfContact
        self.phoneNumber = phoneNumber
        self.email = email
    }

    /// A copy of this event that is not attached to the SwiftData store.
    /// Edit sheets work on the copy so cancelling never changes the saved event.
    func detachedCopy() -> CommunityEvent {
        CommunityEvent(
            id: id,
            name: name,
            businessID: businessID,
            neighborhood: neighborhood,
            location: location,
            peopleReached: peopleReached,
            category: category,
            eventType: eventType,
            date: date,
            coordinate: coordinate,
            pointOfContact: pointOfContact,
            phoneNumber: phoneNumber,
            email: email
        )
    }

    /// Copies every field except `id` from another event onto this one.
    /// Used when an edit sheet saves: the edited copy's values land on the
    /// saved event.
    func update(from other: CommunityEvent) {
        name = other.name
        businessID = other.businessID
        neighborhood = other.neighborhood
        location = other.location
        peopleReached = other.peopleReached
        category = other.category
        eventType = other.eventType
        date = other.date
        latitude = other.latitude
        longitude = other.longitude
        pointOfContact = other.pointOfContact
        phoneNumber = other.phoneNumber
        email = other.email
    }

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

    // Starter dataset for a signed-in account, inserted into the store on
    // first launch. Each one is a `CommunityEvent(...)` built using named
    // arguments — notice some fields (like `pointOfContact`) are skipped
    // because they have defaults above.
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
    // Practice events are never saved to the store.
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
