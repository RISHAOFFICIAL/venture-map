/// Which authentication screen (if any) should be shown on top of the app.
///
/// This is an `enum` — a type with a fixed, named set of possible values.
/// `ContentView` holds an optional `AuthenticationRoute?` in its `@State`.
/// When it's `nil`, no auth screen is shown. When it's `.signIn` or `.signUp`,
/// `ContentView` switches on the value to decide which view to display.
///
/// Enums like this are a very common SwiftUI pattern for "which screen am I
/// on?" style navigation state, because the compiler guarantees you can only
/// ever be in one of the listed cases — there's no way to accidentally set an
/// invalid route.
enum AuthenticationRoute {
    case signIn
    case signUp
}
