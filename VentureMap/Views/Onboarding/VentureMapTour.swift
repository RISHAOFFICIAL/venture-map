import SwiftUI
import Combine

/// The guided tour: instead of the old swipeable word pages
/// (`GuestTutorialView`, deleted), the tour plays *over the real home
/// screen*. Each step dims the screen but leaves the actual element being
/// described — the map, a real pin callout, the + button, the reach card,
/// the menu button — lit at full brightness through a spotlight hole, with
/// a glowing ring around it, and shows one short tip beside it. Tapping
/// anywhere moves on.
///
/// That highlight is the point: the element being talked about keeps its
/// real colors, the way the other apps' tours do, instead of being dimmed
/// out along with everything else. The tip card follows the Where's the
/// Run shape (dark panel, step count, "tap the glowing spot" hint), and
/// the steps set the real screen up first (the pin step opens a real
/// callout, so the spotlight falls on a callout that is actually there).
///
/// How the spotlight finds its target:
/// - Every highlighted view reports its frame up through
///   `TourFramePreferenceKey` (see `tourAnchor(_:)`), measured in the
///   "tour" coordinate space that `VentureMapHomeView` sets on its root.
/// - `VentureMapTourOverlay` reads those frames and cuts a hole in the dim
///   with `SpotlightShape` (an even-odd fill: full rect plus hole).
///
/// The tour is not guest-only: it shows once for anyone entering the map
/// for the first time, guest or signed-in, because a new account has never
/// seen the map either. The copy adapts to who is looking: guests hear
/// about practice entries and signing in, signed-in users hear about
/// logging real events and their profile. It can be replayed from the
/// profile ("Replay the tour"). Finishing or skipping marks it done, so it
/// never auto-repeats — for a guest who saw it and then signs up, or the
/// other way around.

// MARK: - Anchors

/// The home-screen elements the tour can highlight.
enum TourAnchor: Hashable {
    /// The open map between the header and the reach card.
    case map
    /// The event callout floating above a pin.
    case callout
    /// The + button in the header.
    case addButton
    /// The "Your reach" card at the bottom.
    case reachCard
    /// The menu button at the top left.
    case profileButton
}

/// Collects the on-screen frames of every highlighted view, keyed by
/// anchor. A `PreferenceKey` is SwiftUI's way for a deep child view to pass
/// a value *up* to an ancestor: each anchored view writes its frame in,
/// `reduce` merges them, and the home view reads the merged dictionary with
/// `.onPreferenceChange`.
struct TourFramePreferenceKey: PreferenceKey {
    static var defaultValue: [TourAnchor: CGRect] = [:]

    static func reduce(value: inout [TourAnchor: CGRect], nextValue: () -> [TourAnchor: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    /// Reports this view's frame to the tour, so the spotlight can find it.
    /// The frame is measured in the "tour" coordinate space, which the home
    /// view sets on its root — that keeps every anchor in one shared
    /// coordinate system, no matter how deeply nested the view is.
    func tourAnchor(_ anchor: TourAnchor) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(
                        key: TourFramePreferenceKey.self,
                        value: [anchor: proxy.frame(in: .named("tour"))]
                    )
            }
        )
    }
}

// MARK: - Steps and manager

/// One step of the tour: which element to highlight, and what to say about
/// it. The guest copy matches the old tutorial word for word, plus a step
/// for the reach card, which the old pages never covered. Three steps say
/// something different for a signed-in user: the map step (their events
/// are saved samples, not practice), the + step (real events are saved,
/// not practice), and the menu step (they are already signed in).
struct TourStep: Identifiable {
    let id: Int
    let anchor: TourAnchor
    let tip: String
}

/// The tour's brain: which step is showing, whether the tour is up at all,
/// and whether this guest has already finished it. One shared instance, so
/// the home view, the overlay, and the profile's replay row all talk to the
/// same tour.
final class VentureMapTourManager: ObservableObject {
    static let shared = VentureMapTourManager()

    @Published private(set) var isShowing = false
    @Published private(set) var step = 0

    /// Whether the tour is currently running for a guest. Set by whoever
    /// starts the tour; the steps read it to pick their copy.
    private(set) var isGuest = true

    /// The steps, with copy that adapts to who is looking. Steps 2 and 4
    /// are the same for everyone; steps 1, 3, and 5 say something
    /// different for a signed-in user, because practice entries and
    /// signing in do not apply to them.
    var steps: [TourStep] {
        [
            TourStep(
                id: 0,
                anchor: .map,
                tip: isGuest
                    ? "Pan and zoom around a sample neighborhood with practice events already plotted for you."
                    : "Pan and zoom around the map. Sample events are already plotted for you — tap any pin to see how it works."
            ),
            TourStep(
                id: 1,
                anchor: .callout,
                tip: "Select any marker to open a full callout with event details, right on the map."
            ),
            TourStep(
                id: 2,
                anchor: .addButton,
                tip: isGuest
                    ? "Try the + button to see how logging an event works. Practice entries are just for learning and won't be saved."
                    : "Tap + to log an event you held. It appears on your map right away and counts toward your reach."
            ),
            TourStep(
                id: 3,
                anchor: .reachCard,
                tip: "Your reach shows how many people your events reached, across every neighborhood."
            ),
            TourStep(
                id: 4,
                anchor: .profileButton,
                tip: isGuest
                    ? "Ready to track your real outreach? Tap the menu button to sign in or create an account."
                    : "Tap the menu button anytime to see your profile, your businesses, and organizations matched to your focus."
            ),
        ]
    }

    /// One flag, on device, for the tour. It is shared across guest and
    /// signed-in sessions on purpose: seeing the tour once is enough, and a
    /// guest who saw it should not see it again after signing up.
    private let doneKey = "venturemap.tourDone.v1"
    /// The first version of the tour keyed its flag to guests only. A guest
    /// who finished under that key has still seen the tour, so it counts
    /// as done too.
    private let legacyGuestDoneKey = "venturemap.tourDone.v1.guest"

    private init() {}

    var currentStep: TourStep {
        steps[min(max(step, 0), steps.count - 1)]
    }

    var isLastStep: Bool {
        step >= steps.count - 1
    }

    var isDone: Bool {
        UserDefaults.standard.bool(forKey: doneKey)
            || UserDefaults.standard.bool(forKey: legacyGuestDoneKey)
    }

    /// Shows the tour the first time anyone enters the map — guest or
    /// signed-in. Does nothing once the tour has been finished or skipped.
    func startAutomaticallyIfNeeded(isGuest: Bool) {
        self.isGuest = isGuest
        guard !isDone, !isShowing else { return }
        step = 0
        isShowing = true
    }

    /// Shows the tour again on purpose (the profile's "Replay the tour"
    /// row). Works whether or not the tour was finished before.
    func startAgain(isGuest: Bool) {
        self.isGuest = isGuest
        step = 0
        isShowing = true
    }

    func advance() {
        if isLastStep {
            finish()
        } else {
            step += 1
        }
    }

    func skip() {
        finish()
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: doneKey)
        isShowing = false
    }
}

// MARK: - Spotlight

/// The dim with a hole in it. The path is the full rect plus a rounded
/// rect for the hole; filled with the even-odd rule
/// (`FillStyle(eoFill: true)`) the hole stays clear while everything around
/// it dims — that is the spotlight.
///
/// `animatableData` lets the hole glide from one element to the next when
/// the step changes, instead of jumping: SwiftUI interpolates the rect
/// between steps.
struct SpotlightShape: Shape {
    var hole: CGRect
    var cornerRadius: CGFloat = 18

    var animatableData: CGRect.AnimatableData {
        get { hole.animatableData }
        set { hole = CGRect(animatableData: newValue) }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        path.addRoundedRect(
            in: hole,
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
        )
        return path
    }
}

// MARK: - Overlay

/// The overlay that plays over the real home screen while the tour runs:
/// the dim with its spotlight hole, a glowing ring around the highlighted
/// element, and the tip card. Tapping anywhere — the dim, the highlighted
/// element, the card — advances. Skip is always visible.
struct VentureMapTourOverlay: View {
    @ObservedObject private var tour = VentureMapTourManager.shared
    /// Frames of the anchored views, in the "tour" coordinate space.
    let anchors: [TourAnchor: CGRect]

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let hole = holeRect(for: tour.currentStep.anchor, in: size)
            ZStack {
                // The dim, with the spotlight hole cut out of it. The
                // highlighted element shows through at full brightness;
                // everything else dims. Tapping the dim advances.
                SpotlightShape(hole: hole)
                    .fill(Color.black.opacity(0.55), style: FillStyle(eoFill: true))
                    .contentShape(Rectangle())
                    .onTapGesture { tour.advance() }

                // The glow ring around the highlighted element. Its tap
                // area is the whole hole, not just the thin ring, so the
                // highlighted spot is an easy tap target.
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white, lineWidth: 2.5)
                    .frame(width: hole.width, height: hole.height)
                    .position(x: hole.midX, y: hole.midY)
                    .shadow(color: .white.opacity(0.6), radius: 10)
                    .contentShape(Rectangle())
                    .onTapGesture { tour.advance() }

                // Tip card: below the spotlight when it fits, above it
                // when not.
                tipCard(width: size.width - 28)
                    .onTapGesture { tour.advance() }
                    .position(
                        x: size.width / 2,
                        y: cardCenterY(holeMidY: hole.midY, in: size, insets: geometry.safeAreaInsets)
                    )

                // Skip is always visible. It sits top-center, not
                // top-right the way Where's the Run has it, because this
                // app's + button lives top-right and the spotlight would
                // land on top of it there.
                VStack {
                    HStack {
                        Spacer()
                        Button("Skip tour") { tour.skip() }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 44)
                            .background(Color.black.opacity(0.8), in: Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                            .buttonStyle(.plain)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, geometry.safeAreaInsets.top + 12)
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.3), value: tour.step)
    }

    /// The spotlight hole for a step: the anchored view's frame, padded a
    /// little so the ring sits clear of the element. The map step has no
    /// single view to point at, so its hole is the open map between the
    /// header and the reach card, worked out from their frames. If an
    /// anchor hasn't reported yet — the callout is still animating in, or
    /// there are no events to call out — the step falls back to the map.
    private func holeRect(for anchor: TourAnchor, in size: CGSize) -> CGRect {
        switch anchor {
        case .map:
            let headerBottom = max(
                anchors[.profileButton]?.maxY ?? 120,
                anchors[.addButton]?.maxY ?? 120
            )
            let reachTop = anchors[.reachCard]?.minY ?? (size.height - 200)
            let top = min(headerBottom + 8, size.height * 0.5)
            let bottom = max(reachTop - 8, top + 120)
            return CGRect(x: 12, y: top, width: size.width - 24, height: bottom - top)
        case .callout, .addButton, .reachCard, .profileButton:
            if let frame = anchors[anchor] {
                return frame.insetBy(dx: -10, dy: -10)
            }
            return holeRect(for: .map, in: size)
        }
    }

    // MARK: - Tip card

    private func tipCard(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(tour.currentStep.tip)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
            HStack {
                Text("\(tour.step + 1) of \(tour.steps.count)")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                Text("Tap the glowing spot")
                    .font(.system(size: 13))
                    .foregroundStyle(.green)
            }
        }
        .padding(16)
        .frame(width: width, alignment: .leading)
        .background(Color.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private func cardCenterY(holeMidY: CGFloat, in size: CGSize, insets: EdgeInsets) -> CGFloat {
        let below = holeMidY + 128
        if below + 60 <= size.height - insets.bottom {
            return below
        }
        return max(holeMidY - 128, insets.top + 80)
    }
}

#Preview {
    ZStack {
        Color.green.opacity(0.3)
        VentureMapTourOverlay(anchors: [
            .profileButton: CGRect(x: 16, y: 60, width: 38, height: 38),
            .addButton: CGRect(x: 320, y: 60, width: 36, height: 38),
            .reachCard: CGRect(x: 12, y: 640, width: 366, height: 120),
        ])
    }
}
