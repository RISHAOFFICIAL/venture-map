import SwiftUI
import SwiftData

// This is the entry point of the entire app — every SwiftUI app needs exactly
// one type like this.
//
// `@main` tells Swift "start the program here." When the app launches, Swift
// creates this struct and runs its `body`.
//
// `App` is a protocol (a contract). Conforming to it means this type must
// provide a `body` property of some `Scene`. A Scene describes a piece of UI
// that can appear on screen — for example a window on iPad/Mac, or the single
// full-screen view on iPhone.
//
// `.modelContainer(for: CommunityEvent.self)` creates the SwiftData store
// that holds saved events, and hands its `modelContext` down to every view
// in the app through the environment. Views read saved events with `@Query`
// and write them through the context — see `VentureMapHomeView`.
@main struct MyApp: App {
    var body: some Scene {
        // `WindowGroup` is the most common Scene: it manages one or more
        // windows that all show the same root view. On iPhone there's just
        // one window, and `ContentView()` is the very first screen the user sees.
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: CommunityEvent.self)
    }
}
