import SwiftUI

/// The very first screen a brand-new user sees: a full-bleed background with
/// the logo and three choices (sign up, sign in, continue as guest).
///
/// The logo arrives animated: the pin drops in from above, a ripple rings
/// its landing, the globe's lines draw themselves in and dissolve into the
/// real globe, the wordmark rises beneath, and the buttons fade in.
/// About 1.6 seconds end to end, following the same sequenced-animation
/// shape as Where's the Run's splash (a `.task` that steps through the
/// beats, each guarded so leaving the screen mid-animation stops it cleanly).
///
/// Two things that matter about how this is built:
/// - The buttons are live from the first frame. They fade in with the
///   wordmark, but a tap on one works even mid-animation, so the entrance
///   never makes anyone wait. That is why there is no tap-to-skip gesture:
///   there is nothing to wait out.
/// - The mark is two images, split from the one splash asset at the empty
///   band between the ground ring and the wordmark, so each half can move on
///   its own. Stacked with no gap at the same width, they compose exactly
///   the old image — and their green was recolored to this screen's green,
///   so the split is invisible and the faint square edge the old tile left
///   behind is gone. The old single asset stays in the catalog because the
///   sign-in and sign-up forms still show it.
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

    @State private var markOffset: CGFloat = -500
    @State private var rippleScale: CGFloat = 0.6
    @State private var rippleOpacity: Double = 0
    @State private var meridianTrim: CGFloat = 0
    @State private var meridianOpacity: Double = 0
    @State private var wordmarkOffset: CGFloat = 24
    @State private var wordmarkOpacity: Double = 0
    @State private var buttonsShown = false
    @State private var finished = false

    private let ventureGreen = Color(red: 0.18, green: 0.41, blue: 0.24)

    /// The mark image is 320x222 and the wordmark 320x98; both show at 310
    /// wide, so together they are exactly the 310-point square the old
    /// single image was.
    private let markWidth: CGFloat = 310
    private var markHeight: CGFloat { markWidth * 222 / 320 }

    /// The globe inside the mark, measured from the artwork: its center sits
    /// at (161, 83) of the 320x222 mark, with a radius of 50.
    private var globeCenter: CGPoint {
        CGPoint(x: markWidth * 161 / 320, y: markHeight * 83 / 222)
    }
    private var globeRadius: CGFloat { markWidth * 50 / 320 }

    /// The ground ellipse under the pin, measured from the artwork: its
    /// center sits at (159.5, 190) of the mark, radii 66.5 by 11.
    private var ellipseCenter: CGPoint {
        CGPoint(x: markWidth * 159.5 / 320, y: markHeight * 190 / 222)
    }
    private var ellipseSize: CGSize {
        CGSize(width: markWidth * 133 / 320, height: markHeight * 22 / 222)
    }

    var body: some View {
        ZStack {
            ventureGreen
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 0) {
                    ZStack {
                        Image("VentureMapSplashMark")
                            .resizable()
                            .scaledToFit()

                        // The globe's lines, drawn over the real globe and
                        // gone again before the animation ends.
                        GlobeMeridians()
                            .trim(from: 0, to: meridianTrim)
                            .stroke(Color.white, lineWidth: 1.5)
                            .frame(width: globeRadius * 2, height: globeRadius * 2)
                            .position(globeCenter)
                            .opacity(meridianOpacity)

                        // The ripple: a second ground ellipse that grows
                        // out from the landing point and fades.
                        Ellipse()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: ellipseSize.width, height: ellipseSize.height)
                            .position(ellipseCenter)
                            .scaleEffect(rippleScale)
                            .opacity(rippleOpacity)
                    }
                    .frame(width: markWidth, height: markHeight)
                    .offset(y: markOffset)
                    .accessibilityLabel("VentureMap")

                    Image("VentureMapSplashWordmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: markWidth)
                        .offset(y: wordmarkOffset)
                        .opacity(wordmarkOpacity)
                }

                Spacer()

                VStack(spacing: 12) {
                    // `Button("title", action: someClosure)` is shorthand for
                    // `Button(action: someClosure) { Text("title") }`.
                    Button("Sign up", action: onSignUp)
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                        .foregroundStyle(ventureGreen)
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

    /// Drop (~0.45s) → ripple + globe lines (~0.6s) → wordmark rises and
    /// buttons fade in (~0.5s). About 1.6 seconds end to end.
    private func play() async {
        if reduceMotion {
            markOffset = 0
            wordmarkOffset = 0
            wordmarkOpacity = 1
            buttonsShown = true
            finished = true
            return
        }

        // The pin drops in from above.
        withAnimation(.easeIn(duration: 0.45)) { markOffset = 0 }
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

        // The lines dissolve, the wordmark rises, the buttons fade in.
        withAnimation(.easeOut(duration: 0.3)) { meridianOpacity = 0 }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            wordmarkOffset = 0
            wordmarkOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.35)) { buttonsShown = true }
        await nap(0.5)
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
    /// The button stays tappable the whole time.
    func splashButton(shown: Bool, delay: Double) -> some View {
        opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 12)
            .animation(.easeOut(duration: 0.35).delay(delay), value: shown)
    }
}
