import SwiftUI
import MapKit

/// One suggested address returned from an Apple Maps search, shown while
/// typing a location in `AddEventView`.
///
/// `CLLocationCoordinate2D` comes from `MapKit`/`CoreLocation` — it's a
/// simple pair of `latitude`/`longitude` `Double`s representing a point on
/// Earth. Any type that needs to say "here's a specific map location" ends
/// up storing one of these (see also `CommunityEvent.coordinate`).
struct AddressLookupResult: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
}
