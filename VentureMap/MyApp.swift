import SwiftUI

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
@main struct MyApp: App {
    var body: some Scene {
        // `WindowGroup` is the most common Scene: it manages one or more
        // windows that all show the same root view. On iPhone there's just
        // one window, and `ContentView()` is the very first screen the user sees.
        WindowGroup {
            ContentView()
        }
    }
}
