import SwiftUI

/// The very first screen a brand-new user sees: a full-bleed background with
/// the logo and three choices (sign up, sign in, continue as guest).
///
/// The logo arrives animated: the ground ring is already down, the pin
/// drops in from above and lands on it, a ripple rings the landing, the
/// globe's grid lines draw themselves in one after another, the wordmark
/// fades in beneath, and the buttons fade in. About 1.5 seconds end to
/// end, following the same sequenced-animation shape as Where's the Run's
/// splash (a `.task` that steps through the beats, each guarded so
/// leaving the screen mid-animation stops it cleanly).
///
/// Two things that matter about how this is built:
/// - The buttons are live from the first frame. They fade in with the
///   wordmark, but a tap on one works even mid-animation, so the entrance
///   never makes anyone wait. That is why there is no tap-to-skip gesture:
///   there is nothing to wait out.
/// - The mark is three images, split from the one splash asset so each part
///   can move on its own: the ground ring (`VentureMapSplashEllipse`), the
///   pin and globe (`VentureMapSplashPin`), and the wordmark
///   (`VentureMapSplashWordmark`). The ring and the pin share one frame —
///   the ring sits in its rest position from the first frame while the pin
///   drops onto it. The pin image is transparent, which is what makes the
///   stacking work: two opaque tiles would hide each other, but the
///   transparent pin lets the ring show through everywhere the pin isn't.
///   The pin's globe has no grid lines in it — the lines are drawn by the
///   overlay below, traced from the artwork itself, so they can draw in
///   for real instead of sitting baked into the image. With the lines
///   drawn, the stack reproduces the original mark (verified against the
///   artwork). The screen's green is the logo's own green
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
    // One trim per grid line, so they draw in one after another instead
    // of all at once. The lines stay drawn — the pin image has no grid
    // lines in it, so the overlay *is* the lines at rest.
    @State private var diagonalTrim: CGFloat = 0
    @State private var meridianTrim: CGFloat = 0
    @State private var tropicTrim: CGFloat = 0
    @State private var tropicEndTrim: CGFloat = 0
    @State private var wordmarkOpacity: Double = 0
    @State private var buttonsShown = false
    @State private var finished = false

    /// The pin and ring images are 320x222 and the wordmark 320x98; all
    /// show at 310 wide, so the pin and ring stack into a 310-point square
    /// with the wordmark beneath, exactly the old single image's footprint.
    private let artWidth: CGFloat = 310
    private var artHeight: CGFloat { artWidth * 222 / 320 }

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

                        // The globe's grid lines, traced from the artwork
                        // and drawn in one after another. They stay drawn:
                        // the pin image has no grid lines, so these are
                        // the lines at rest, not a temporary effect.
                        meridianLine(points: Self.diagonalPoints, trim: diagonalTrim)
                        meridianLine(points: Self.meridianPoints, trim: meridianTrim)
                        meridianLine(points: Self.tropicPoints, trim: tropicTrim)
                        meridianLine(points: Self.tropicEndPoints, trim: tropicEndTrim)
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

    /// One grid line, drawn along its traced path and trimmed by `trim`
    /// (0 is not drawn yet, 1 is fully drawn). The stroke matches the
    /// artwork's own lines: about a point wide, round at the ends.
    private func meridianLine(points: [CGPoint], trim: CGFloat) -> some View {
        TracedMeridian(points: points)
            .trim(from: 0, to: trim)
            .stroke(Color.white, style: StrokeStyle(lineWidth: 1.25, lineCap: .round, lineJoin: .round))
            .frame(width: artWidth, height: artHeight)
    }

    // MARK: - Animation

    /// The ring is already down. Pin drop (~0.45s) → ripple + the four
    /// grid lines drawing in, staggered (~0.6s) → wordmark fades in and
    /// buttons fade in (~0.4s). About 1.5 seconds end to end.
    private func play() async {
        if reduceMotion {
            pinOffset = 0
            diagonalTrim = 1
            meridianTrim = 1
            tropicTrim = 1
            tropicEndTrim = 1
            wordmarkOpacity = 1
            buttonsShown = true
            finished = true
            return
        }

        // The pin drops in from above and lands on the ring.
        withAnimation(.easeIn(duration: 0.45)) { pinOffset = 0 }
        await nap(0.45)
        guard stillPlaying() else { return }

        // On landing, the ripple rings out and the globe's grid lines
        // draw in one after another: the diagonal first, then the
        // meridian, then the tropic and its end dash. The lines stay
        // drawn — they are the globe's grid now, not a passing effect.
        rippleOpacity = 0.8
        withAnimation(.easeOut(duration: 0.5)) {
            rippleScale = 1.7
            rippleOpacity = 0
        }
        withAnimation(.easeInOut(duration: 0.45)) { diagonalTrim = 1 }
        withAnimation(.easeInOut(duration: 0.45).delay(0.15)) { meridianTrim = 1 }
        withAnimation(.easeInOut(duration: 0.3).delay(0.3)) { tropicTrim = 1 }
        withAnimation(.easeInOut(duration: 0.15).delay(0.45)) { tropicEndTrim = 1 }
        await nap(0.6)
        guard stillPlaying() else { return }

        // The wordmark fades in, the buttons fade in.
        withAnimation(.easeOut(duration: 0.4)) { wordmarkOpacity = 1 }
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

/// One of the globe's grid lines, traced from the artwork itself: the
/// points are measured positions of the line in the 320x222 art frame,
/// and the shape scales them into whatever frame it is drawn in. Trimmed
/// from 0 to 1, the line draws itself in along its real path — not an
/// ellipse guessed at the shape, but the line as the artist drew it.
/// (The first version drew ellipses; the real lines are a diagonal, a
/// meridian arc, and a tropic, none of which is an ellipse.)
private struct TracedMeridian: Shape {
    /// Points in the 320x222 art frame, in draw order.
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        let scaleX = rect.width / 320
        let scaleY = rect.height / 222
        path.move(to: CGPoint(x: first.x * scaleX, y: first.y * scaleY))
        for point in points.dropFirst() {
            path.addLine(to: CGPoint(x: point.x * scaleX, y: point.y * scaleY))
        }
        return path
    }
}

private extension SplashView {
    /// The diagonal line across the Atlantic, lower-left to upper-right.
    static let diagonalPoints: [CGPoint] = [
        CGPoint(x: 125, y: 102.1), CGPoint(x: 137, y: 91.5),
        CGPoint(x: 142, y: 87.6), CGPoint(x: 144, y: 85),
        CGPoint(x: 154, y: 80.3), CGPoint(x: 159, y: 78.9),
        CGPoint(x: 161, y: 76.9), CGPoint(x: 174, y: 69.1),
        CGPoint(x: 179, y: 66.3), CGPoint(x: 186, y: 58),
    ]

    /// The meridian arc down the globe's left side and along the bottom.
    static let meridianPoints: [CGPoint] = [
        CGPoint(x: 117.3, y: 76.3), CGPoint(x: 116, y: 86),
        CGPoint(x: 117.9, y: 95), CGPoint(x: 121.2, y: 99.4),
        CGPoint(x: 127.7, y: 105), CGPoint(x: 137, y: 112),
        CGPoint(x: 148.7, y: 118.6), CGPoint(x: 150.9, y: 124),
        CGPoint(x: 153.2, y: 126.2),
    ]

    /// The tropic line below South America.
    static let tropicPoints: [CGPoint] = [
        CGPoint(x: 140, y: 113), CGPoint(x: 159.9, y: 120),
        CGPoint(x: 177, y: 119.5),
    ]

    /// The short dash at the tropic's right end.
    static let tropicEndPoints: [CGPoint] = [
        CGPoint(x: 187, y: 114.5), CGPoint(x: 191.5, y: 114.5),
    ]
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
