import SwiftUI

/// The very first screen a brand-new user sees: a full-bleed background with
/// the logo and three choices (sign up, sign in, continue as guest).
///
/// This view has no `@State` of its own — it's a "dumb" presentational view.
/// All three buttons just call a closure that was handed to it by its parent
/// (`ContentView`). This is a recurring pattern in this codebase: views that
/// display things and report taps outward via closures, while the *parent*
/// decides what those taps actually mean/do.
struct SplashView: View {
    let onSignIn: () -> Void
    let onSignUp: () -> Void
    let onGuest: () -> Void

    var body: some View {
        // `ZStack` layers its children back-to-front — here, a solid color
        // background behind the logo and buttons.
        ZStack {
            Color(red: 0.18, green: 0.41, blue: 0.24)
                .ignoresSafeArea()

            VStack {
                Spacer()

                Image("VentureMapSplash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 310)
                    .accessibilityLabel("VentureMap")

                Spacer()

                VStack(spacing: 12) {
                    // `Button("title", action: someClosure)` is shorthand for
                    // `Button(action: someClosure) { Text("title") }`.
                    Button("Sign up", action: onSignUp)
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                        .foregroundStyle(Color(red: 0.18, green: 0.41, blue: 0.24))
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)

                    Button("Sign in", action: onSignIn)
                        .buttonStyle(.bordered)
                        .tint(.white)
                        .foregroundStyle(.white)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)

                    Button("Continue as guest", action: onGuest)
                        .foregroundStyle(.white)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
    }
}
