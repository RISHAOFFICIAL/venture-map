import SwiftUI

/// A rough "how big was this event" bucket, used to color-code map markers.
///
/// This enum has no raw value (compare with `EventType`, which is
/// `String`-backed) — these cases don't need to be saved or displayed as
/// text directly, they just drive logic inside this file.
///
/// Notice `color` and `title` below: these are **computed properties**. They
/// look like stored variables from the outside (`category.color`), but
/// every time you read them, the `switch` runs again to calculate the
/// answer. Nothing is actually stored — it's calculated on demand.
enum EventCategory {
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
