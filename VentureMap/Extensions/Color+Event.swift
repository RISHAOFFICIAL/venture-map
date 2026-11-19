import SwiftUI

// An `extension` adds new functionality to a type you don't own — here,
// Apple's own `Color` type. Instead of making a new "EventColors" type and
// writing `EventColors.red` everywhere, this lets the rest of the app write
// the shorter, more natural `Color.eventRed`.
//
// This is a very common Swift pattern: define your app's custom colors (or
// fonts, or other constants) as `static` properties in an extension on the
// built-in type, right alongside Apple's own `.red`, `.blue`, etc.
extension Color {
    static let eventRed = Color(red: 1.0, green: 0.29, blue: 0.28)
    static let eventOrange = Color(red: 1.0, green: 0.62, blue: 0.12)
    static let eventYellow = Color(red: 1.0, green: 0.83, blue: 0.08)

    /// The app's green — the logo's own green (#426542), measured from the
    /// artwork's tile. The splash screen, the sign-in/sign-up forms, and
    /// the guest banner all use this one value, so the logo tile melts
    /// into the screens with no seam and no square edge. It lives here, in
    /// one place, so the green can never drift apart again: change it here
    /// and every green surface in the app follows.
    static let ventureGreen = Color(red: 0.2588, green: 0.3961, blue: 0.2588)
}
