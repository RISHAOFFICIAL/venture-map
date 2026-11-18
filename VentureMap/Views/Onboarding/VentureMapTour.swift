import SwiftUI

/// The guided tour: instead of the old swipeable word pages
/// (`GuestTutorialView`, deleted), the tour plays *over the real home
/// screen*. Each step dims the screen, rings the actual element being
/// described — the map, a real pin callout, the + button, the reach card,
/// the menu button — and shows one short tip beside it. Tapping anywhere
/// moves on.
///
/// This follows the Where's the Run tour beat for beat: a dim overlay, a
/// glowing pulsing ring that glides to the next target, a tip card with a
/// step count and a "tap the glowing spot" hint, Skip always visible, and
/// steps that set the real screen up first (the pin step opens a real
/// callout, so the ring points at a callout that is actually there).
///
/// How the ring finds its target:
/// - Every ringed view reports its frame up through
///   `TourFramePreferenceKey` (see `tourAnchor(_:)`), measured in the
///   "tour" coordinate space that `VentureMapHomeView` sets on its root.
/// - `VentureMapTourOverlay` reads those frames and centers the ring on
///   the current step's element. The map step has no single view, so its
///   ring sits at the center of the open map.
///
/// The tour is guest-only, shows once automatically, and can be replayed
/// from the guest profile ("Replay the tour"). Finishing or skipping marks
/// it done, so it never auto-repeats.

// MARK: - Anchors

/// The home-screen elements the tour can ring.
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

/// Collects the on-screen frames of every ringed view, keyed by
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
    /// Reports this view's frame to the tour, so the ring can find it.
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

/// One step of the tour: which element to ring, and what to say about it.
/// The copy matches the old tutorial word for word, plus a step for the
/// reach card, which the old pages never covered.
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

    let steps: [TourStep] = [
        TourStep(
            id: 0,
            anchor: .map,
            tip: "Pan and zoom around a sample neighborhood with practice events already plotted for you."
        ),
        TourStep(
            id: 1,
            anchor: .callout,
            tip: "Select any marker to open a full callout with event details, right on the map."
        ),
        TourStep(
            id: 2,
            anchor: .addButton,
            tip: "Try the + button to see how logging an event works. Practice entries are just for learning and won't be saved."
        ),
        TourStep(
            id: 3,
            anchor: .reachCard,
            tip: "Your reach shows how many people your events reached, across every neighborhood."
        ),
        TourStep(
            id: 4,
            anchor: .profileButton,
            tip: "Ready to track your real outreach? Tap the menu button to sign in or create an account."
        ),
    ]

    /// One flag, on device, for the guest tour. Guests have no account, so
    /// there is nothing per-account to key by — one tour, one flag.
    private let doneKey = "venturemap.tourDone.v1.guest"

    private init() {}

    var currentStep: TourStep {
        steps[min(max(step, 0), steps.count - 1)]
    }

    var isLastStep: Bool {
        step >= steps.count - 1
    }

    var isDone: Bool {
        UserDefaults.standard.bool(forKey: doneKey)
    }

    /// Shows the tour the first time a guest enters the app. Does nothing
    /// once the tour has been finished or skipped.
    func startAutomaticallyIfNeeded() {
        guard !isDone, !isShowing else { return }
        step = 0
        isShowing = true
    }

    /// Shows the tour again on purpose (the profile's "Replay the tour"
    /// row). Works whether or not the tour was finished before.
    func startAgain() {
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

// MARK: - Overlay

/// The overlay that plays over the real home screen while the tour runs:
/// the dim, the glowing ring on the current element, and the tip card.
/// Tapping anywhere — the dim, the ring, the card — advances instantly.
/// Skip is always visible.
struct VentureMapTourOverlay: View {
    @ObservedObject private var tour = VentureMapTourManager.shared
    /// Frames of the anchored views, in the "tour" coordinate space.
    let anchors: [TourAnchor: CGRect]

    @State private var pulsing = false

    /// The app's green, matching the splash screen.
    private let ventureGreen = Color(red: 0.18, green: 0.41, blue: 0.24)

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let center = ringCenter(for: tour.currentStep.anchor, in: size)
            ZStack {
                // Dim overlay; tapping it advances.
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { tour.advance() }

                // Glowing ring at the current target. It glides quickly
                // to the next target; the tip text and counter change
                // synchronously on tap.
                ring
                    .contentShape(Circle())
                    .onTapGesture { tour.advance() }
                    .position(center)
                    .animation(.easeOut(duration: 0.12), value: tour.step)

                // Tip card: below the ring when it fits, above it when not.
                tipCard(width: size.width - 28)
                    .onTapGesture { tour.advance() }
                    .position(
                        x: size.width / 2,
                        y: cardCenterY(ringY: center.y, in: size, insets: geometry.safeAreaInsets)
                    )

                // Skip is always visible. It sits top-center, not
                // top-right the way Where's the Run has it, because this
                // app's + button lives top-right and the ring would land
                // on top of it there.
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
        .onAppear { pulsing = true }
    }

    // MARK: - Ring

    private var ring: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 96, height: 96)
            Circle()
                .stroke(Color.white, lineWidth: 2.5)
                .frame(width: 76, height: 76)
        }
        .scaleEffect(pulsing ? 1.12 : 1.0)
        .opacity(pulsing ? 0.85 : 1.0)
        .animation(
            .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
            value: pulsing
        )
        .shadow(color: ventureGreen.opacity(0.6), radius: 12)
    }

    /// The ring's center for a step: the anchored view's center. The map
    /// step has no single view to point at, so its ring sits at the center
    /// of the open map between the header and the reach card. If an anchor
    /// hasn't reported yet — the callout is still animating in, or there
    /// are no events to call out — the step falls back to the map.
    private func ringCenter(for anchor: TourAnchor, in size: CGSize) -> CGPoint {
        switch anchor {
        case .map:
            return mapCenter(in: size)
        case .callout, .addButton, .reachCard, .profileButton:
            if let frame = anchors[anchor] {
                return CGPoint(x: frame.midX, y: frame.midY)
            }
            return mapCenter(in: size)
        }
    }

    private func mapCenter(in size: CGSize) -> CGPoint {
        let headerBottom = max(
            anchors[.profileButton]?.maxY ?? 120,
            anchors[.addButton]?.maxY ?? 120
        )
        let reachTop = anchors[.reachCard]?.minY ?? (size.height - 200)
        let top = min(headerBottom + 8, size.height * 0.5)
        let bottom = max(reachTop - 8, top + 120)
        return CGPoint(x: size.width / 2, y: (top + bottom) / 2)
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

    private func cardCenterY(ringY: CGFloat, in size: CGSize, insets: EdgeInsets) -> CGFloat {
        let below = ringY + 128
        if below + 60 <= size.height - insets.bottom {
            return below
        }
        return max(ringY - 128, insets.top + 80)
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
