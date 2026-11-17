import SwiftUI

/// A rough "how big was this event" bucket, used to color-code map markers.
///
/// The `String` raw value plus `Codable` is what lets SwiftData store this
/// enum on a `CommunityEvent` — the case name is saved as text and decoded
/// back when the event is loaded.
///
/// Notice `color` and `title` below: these are **computed properties**. They
/// look like stored variables from the outside (`category.color`), but
/// every time you read them, the `switch` runs again to calculate the
/// answer. Nothing is actually stored — it's calculated on demand.
enum EventCategory: String, Codable {
    case red
    case orange
    case yellow
    case communityEvent

    var color: Color {
        switch self {
        case .red: .eventRed
        case .orange: .eventOrange
        case .yellow: .eventYellow
        case .communityEvent: .eventYellow
        }
    }

    var title: String {
        switch self {
        case .red, .orange, .yellow: "Community event"
        case .communityEvent: "Community event"
        }
    }
}
