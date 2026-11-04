import CoreLocation

/// Owns the Core Location permission flow and one-shot location fetch for
/// the "center on me" button.
///
/// Why a separate class? `CLLocationManager` reports results through the
/// `CLLocationManagerDelegate` protocol, and delegates must be classes —
/// a SwiftUI `View` is a struct, so it can't be one. This tiny
/// `ObservableObject` sits between the manager and the view.
///
/// Flow:
///   1. The view calls `requestLocation(then:)` with a closure.
///   2. If permission was never asked, the system prompt appears first.
///   3. Once authorized, a one-shot `requestLocation()` fires.
///   4. `didUpdateLocations` hands the coordinate to the closure.
///
/// NOTE: this only works if the app's Info.plist contains
/// `NSLocationWhenInUseUsageDescription` (Xcode target → Info tab → add
/// "Privacy - Location When InUse Usage Description"). Without that key,
/// iOS never shows the permission prompt and the button silently does
/// nothing — which is the most common cause of a "dead" location button.
final class UserLocationProvider: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    private var onLocation: ((CLLocationCoordinate2D) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Ensures location permission, then calls `handler` once with the
    /// user's coordinate. Safe to call repeatedly — each call replaces the
    /// previous pending handler.
    func requestLocation(then handler: @escaping (CLLocationCoordinate2D) -> Void) {
        onLocation = handler
        switch manager.authorizationStatus {
        case .notDetermined:
            // The system permission prompt appears; if granted,
            // `locationManagerDidChangeAuthorization` below picks up the flow.
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            // Permission was refused — nothing to fetch. (A future
            // improvement: offer a button that opens Settings.)
            break
        @unknown default:
            break
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // The user just answered the permission prompt — if they said yes,
        // go fetch the location now.
        if manager.authorizationStatus == .authorizedWhenInUse
            || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = locations.last?.coordinate {
            onLocation?(coordinate)
            onLocation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // One-shot fetch failed (e.g. no GPS fix). Clear the handler so a
        // later tap starts fresh.
        onLocation = nil
    }
}
