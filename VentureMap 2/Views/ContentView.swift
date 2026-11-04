import SwiftUI

/// The root view of the app. Everything else on screen is shown by (or
/// inside of) this view.
///
/// This is a great first file to read, because it shows off the core
/// SwiftUI building blocks all at once:
///
/// - **`View` protocol**: Every screen/component in SwiftUI is a `struct`
///   that conforms to `View`. The only requirement is a `body` property that
///   describes what to draw. SwiftUI calls `body` every time it needs to
///   redraw this view — which is why `body` should be a pure description of
///   "what should be on screen right now," not a place to do side effects.
///
/// - **`@State`**: A property wrapper for small pieces of data a view *owns*
///   and can change over time (here: which auth screen is active, whether
///   the user has gotten past the splash screen, whether they're a guest).
///   When a `@State` value changes, SwiftUI automatically re-runs `body` to
///   reflect it — you never manually tell the UI to refresh.
///
/// - **`@AppStorage`**: Like `@State`, but automatically persisted to
///   `UserDefaults`. `hasEnteredVentureMap` survives app relaunches, which is
///   how the app remembers "this person has signed in before."
///
/// - **Conditional view building**: `body` is just an `if`/`else if`/`else`
///   chain that returns a different child view depending on current state.
///   SwiftUI is fine with a `body` that returns different view types from
///   different branches, as long as every branch returns *some* `View`.
struct ContentView: View {
    @AppStorage("hasEnteredVentureMap") private var hasEnteredVentureMap = false
    @State private var route: AuthenticationRoute?
    @State private var hasPassedEntry = false
    @State private var isGuest = false

    var body: some View {
        if let route {
            // `if let route` "unwraps" the optional: inside this block,
            // `route` is guaranteed non-nil, so we can switch on it safely.
            switch route {
            case .signIn:
                SignInView(
                    // These are **closures** (small inline functions) passed
                    // as arguments. This is how a child view (SignInView)
                    // communicates back up to its parent (ContentView)
                    // without needing to know anything about ContentView
                    // itself — it just calls `onCancel()` or `onComplete()`
                    // when something happens.
                    onCancel: { self.route = nil },
                    onComplete: {
                        hasEnteredVentureMap = true
                        hasPassedEntry = true
                        self.route = nil
                    }
                )
            case .signUp:
                SignUpView(
                    onCancel: { self.route = nil },
                    onComplete: {
                        hasEnteredVentureMap = true
                        hasPassedEntry = true
                        self.route = nil
                    }
                )
            }
        } else if hasPassedEntry && (hasEnteredVentureMap || isGuest) {
            VentureMapHomeView(
                isGuest: isGuest,
                onRequireSignIn: {
                    isGuest = false
                    route = .signIn
                },
                onRequireSignUp: {
                    isGuest = false
                    route = .signUp
                }
            )
        } else {
            SplashView(
                onSignIn: { route = .signIn },
                onSignUp: { route = .signUp },
                onGuest: {
                    isGuest = true
                    hasPassedEntry = true
                }
            )
        }
    }
}

// `#Preview` builds a lightweight, Xcode-only preview of this view so you
// can see your UI update live in the canvas without running the whole app
// in the simulator.
#Preview {
    ContentView()
}
