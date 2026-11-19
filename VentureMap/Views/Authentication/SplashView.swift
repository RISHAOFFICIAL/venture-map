import SwiftUI

/// The very first screen a brand-new user sees: a full-bleed background with
/// the logo and three choices (sign up, sign in, continue as guest).
///
/// The logo arrives animated: the ground ring is already down, the pin
/// drops in from above and lands on it, a ripple rings the landing, the
/// globe's lines draw themselves in and dissolve into the real globe, the
/// wordmark fades in beneath, and the buttons fade in. About 1.5 seconds
/// end to end, following the same sequenced-animation shape as Where's the
/// Run's splash (a `.task` that steps through the beats, each guarded so
/// leaving the screen mid-animation stops it cleanly).
///
/// Two things that matter about how this is built:
/// - The buttons become tappable as they fade in. Before that they are
///   disabled, so a tap in the first second cannot trigger a sign-up the
///   user cannot see yet (opacity 0 still hit-tests in SwiftUI).
/// - The animation plays once per launch. If the user backs out of
///   sign-in and lands here again, the settled screen shows at once
///   instead of replaying: the played flag lives on the type, not the
///   instance, because @State resets when the view is recreated.
/// - The mark is three images, split from the one splash asset so each part
///   can move on its own: the ground ring (`VentureMapSplashEllipse`), the
///   pin and globe (`VentureMapSplashPin`), and the wordmark
///   (`VentureMapSplashWordmark`). The ring and the pin share one frame —
///   the ring sits in its rest position from the first frame while the pin
///   drops onto it — and stacked they reproduce the original mark exactly
///   (verified pixel for pixel). The pin image is transparent, which is
///   what makes the stacking work: two opaque tiles would hide each other,
///   but the transparent pin lets the ring show through everywhere the pin
///   isn't. The screen's green is the logo's own green
///   (`Color.ventureGreen`, #426542, measured from the artwork), so the
///   tiles melt into the background with no seam and no square edge — the
///   app matches the logo, not the other way around. The old single asset
///   stays in the catalog because the sign-in and sign-up forms still show
///   it.
///
/// Reduced motion shows the settled screen at once, with no animation.
///
/// This view is otherwise still a "dumb" presentational view: all three
/// buttons just call a closure handed to it by its parent (`ContentView`).
struct SplashView: View {
    let onSignIn: () -> Void
    let onSignUp: () -> Void
    let onGuest: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pinOffset: CGFloat = -500
    @State private var rippleScale: CGFloat = 0.6
    @State private var rippleOpacity: Double = 0
    @State private var meridianTrim: CGFloat = 0
    @State private var meridianOpacity: Double = 0
    @State private var wordmarkOpacity: Double = 0
    @State private var buttonsShown = false
    @State private var finished = false

    /// Whether the entrance has played once this launch. A static, not
    /// @State: the view is recreated when the user returns from sign-in,
    /// which would reset @State and replay the animation.
    private static var playedThisLaunch = false

    /// The pin and ring images are 320x222 and the wordmark 320x98; all
    /// show at 310 wide, so the pin and ring stack into a 310-point square
    /// with the wordmark beneath, exactly the old single image's footprint.
    private let artWidth: CGFloat = 310
    private var artHeight: CGFloat { artWidth * 222 / 320 }

    /// The globe inside the pin, measured from the artwork: its center sits
    /// at (161, 83) of the 320x222 art, with a radius of 50.
    private var globeCenter: CGPoint {
        CGPoint(x: artWidth * 161 / 320, y: artHeight * 83 / 222)
    }
    private var globeRadius: CGFloat { artWidth * 50 / 320 }

    /// The ground ring under the pin, measured from the artwork: its center
    /// sits at (159.5, 193.5) of the art, 133 wide by 37 tall. The ripple
    /// rings out from this same ellipse.
    private var ringCenter: CGPoint {
        CGPoint(x: artWidth * 159.5 / 320, y: artHeight * 193.5 / 222)
    }
    private var ringSize: CGSize {
        CGSize(width: artWidth * 133 / 320, height: artHeight * 37 / 222)
    }

    var body: some View {
        ZStack {
            Color.ventureGreen
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 0) {
                    ZStack {
                        // The ground ring, already down from the first
                        // frame. It never moves.
                        Image("VentureMapSplashEllipse")
                            .resizable()
                            .scaledToFit()

                        // The ripple: a second ground ellipse that grows
                        // out from the landing point and fades. It sits
                        // under the pin, the way a ripple on the ground
                        // passes behind the thing that landed.
                        Ellipse()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: ringSize.width, height: ringSize.height)
                            .position(ringCenter)
                            .scaleEffect(rippleScale)
                            .opacity(rippleOpacity)

                        // The pin and globe, dropping onto the ring. The
                        // image is transparent, so the ring shows through
                        // everywhere the pin isn't.
                        Image("VentureMapSplashPin")
                            .resizable()
                            .scaledToFit()
                            .offset(y: pinOffset)

                        // The globe's lines, drawn over the real globe and
                        // gone again before the animation ends.
                        GlobeMeridians()
                            .trim(from: 0, to: meridianTrim)
                            .stroke(Color.white, lineWidth: 1.5)
                            .frame(width: globeRadius * 2, height: globeRadius * 2)
                            .position(globeCenter)
                            .opacity(meridianOpacity)
                    }
                    .frame(width: artWidth, height: artHeight)
                    .accessibilityLabel("VentureMap")

                    Image("VentureMapSplashWordmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: artWidth)
                        .opacity(wordmarkOpacity)
                }

                Spacer()

                VStack(spacing: 12) {
                    // `Button("title", action: someClosure)` is shorthand for
                    // `Button(action: someClosure) { Text("title") }`.
                    Button("Sign up", action: onSignUp)
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                        .foregroundStyle(Color.ventureGreen)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        .splashButton(shown: buttonsShown, delay: 0)

                    Button("Sign in", action: onSignIn)
                        .buttonStyle(.bordered)
                        .tint(.white)
                        .foregroundStyle(.white)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        .splashButton(shown: buttonsShown, delay: 0.08)

                    Button("Continue as guest", action: onGuest)
                        .foregroundStyle(.white)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .splashButton(shown: buttonsShown, delay: 0.16)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
        .task { await play() }
    }

    // MARK: - Animation

    /// The ring is already down. Pin drop (~0.45s) → ripple + globe lines
    /// (~0.6s) → wordmark fades in and buttons fade in (~0.4s). About 1.5
    /// seconds end to end. Plays once per launch; a returning user gets
    /// the settled screen at once.
    private func play() async {
        if Self.playedThisLaunch {
            settle()
            return
        }
        Self.playedThisLaunch = true

        if reduceMotion {
            settle()
            return
        }

        // The pin drops in from above and lands on the ring.
        withAnimation(.easeIn(duration: 0.45)) { pinOffset = 0 }
        await nap(0.45)
        guard stillPlaying() else { return }

        // On landing, the ripple rings out and the globe's lines draw in.
        rippleOpacity = 0.8
        meridianOpacity = 0.9
        withAnimation(.easeOut(duration: 0.5)) {
            rippleScale = 1.7
            rippleOpacity = 0
        }
        withAnimation(.easeInOut(duration: 0.6)) { meridianTrim = 1 }
        await nap(0.6)
        guard stillPlaying() else { return }

        // The lines dissolve, the wordmark fades in, the buttons fade in.
        withAnimation(.easeOut(duration: 0.3)) { meridianOpacity = 0 }
        withAnimation(.easeOut(duration: 0.4)) { wordmarkOpacity = 1 }
        withAnimation(.easeOut(duration: 0.35)) { buttonsShown = true }
        await nap(0.5)
        finished = true
    }

    /// The settled screen: pin down, wordmark and buttons in, no motion.
    /// Used for Reduce Motion and for a returning user who already saw the
    /// entrance once this launch.
    private func settle() {
        pinOffset = 0
        wordmarkOpacity = 1
        buttonsShown = true
        finished = true
    }

    private func nap(_ seconds: Double) async {
        try? await Task.sleep(for: .seconds(seconds))
    }

    private func stillPlaying() -> Bool {
        !Task.isCancelled && !finished
    }
}

/// The globe's lines: two meridians and one equator, drawn as ellipses
/// inside the globe's circle. Trimmed from 0 to 1, they draw themselves in.
private struct GlobeMeridians: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let cy = rect.midY
        let r = min(rect.width, rect.height) / 2
        // Meridians: tall, narrow ellipses.
        path.addEllipse(in: CGRect(x: cx - r * 0.55, y: cy - r, width: r * 1.1, height: r * 2))
        path.addEllipse(in: CGRect(x: cx - r * 0.22, y: cy - r, width: r * 0.44, height: r * 2))
        // Equator: short, wide ellipse.
        path.addEllipse(in: CGRect(x: cx - r, y: cy - r * 0.3, width: r * 2, height: r * 0.6))
        return path
    }
}

private extension View {
    /// A splash button's entrance: fades and rises in once `shown` flips,
    /// staggered by `delay` so the three buttons arrive one after another.
    /// The button is disabled until it starts fading in, so an invisible
    /// button can never be tapped.
    func splashButton(shown: Bool, delay: Double) -> some View {
        opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 12)
            .animation(.easeOut(duration: 0.35).delay(delay), value: shown)
            .disabled(!shown)
    }
}
