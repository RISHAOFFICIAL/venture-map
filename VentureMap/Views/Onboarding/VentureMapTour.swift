import SwiftUI

/// The guided tour: instead of the old swipeable word pages
/// (`GuestTutorialView`, deleted), the tour plays *over the real home
/// screen*. Each step dims the screen, spotlights the actual element being
/// described — the map, a real pin callout, the + button, the reach card,
/// the menu button — and shows one short tip. Tapping the highlighted
/// spot, or Next, moves on.
///
/// How the spotlight finds its target:
/// - Every spotlighted view reports its frame up through
///   `TourFramePreferenceKey` (see `tourAnchor(_:)`), measured in the
///   "tour" coordinate space that `VentureMapHomeView` sets on its root.
/// - `VentureMapTourOverlay` reads those frames and cuts a hole in the dim
///   with `SpotlightShape` (an even-odd fill: full rect plus hole).
///
/// The tour is guest-only, shows once automatically, and can be replayed
/// from the guest profile ("Replay the tour"). Finishing or skipping marks
/// it done, so it never auto-repeats.

// MARK: - Anchors

/// The home-screen elements the tour can spotlight.
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

/// Collects the on-screen frames of every spotlighted view, keyed by
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

/// One step of the tour: which element to spotlight, and what to say about
/// it. The copy matches the old tutorial word for word, plus a step for the
/// reach card, which the old pages never covered.
struct TourStep: Identifiable {
    let id: Int
    let anchor: TourAnchor
    let icon: String
    let tint: Color
    /// Short label for the icon chip in the tip card.
    let label: String
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
            icon: "map.fill",
            tint: .green,
            label: "Map",
            tip: "Pan and zoom around a sample neighborhood with practice events already plotted for you."
        ),
        TourStep(
            id: 1,
            anchor: .callout,
            icon: "mappin.and.ellipse",
            tint: .red,
            label: "Pin",
            tip: "Select any marker to open a full callout with event details, right on the map."
        ),
        TourStep(
            id: 2,
            anchor: .addButton,
            icon: "plus.circle.fill",
            tint: .blue,
            label: "Add Event",
            tip: "Try the + button to see how logging an event works. Practice entries are just for learning and won't be saved."
        ),
        TourStep(
            id: 3,
            anchor: .reachCard,
            icon: "chart.bar.fill",
            tint: .orange,
            label: "Reach",
            tip: "Your reach shows how many people your events reached, across every neighborhood."
        ),
        TourStep(
            id: 4,
            anchor: .profileButton,
            icon: "person.crop.circle.badge.checkmark",
            tint: .purple,
            label: "Profile",
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

    func back() {
        guard step > 0 else { return }
        step -= 1
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

/// A full-screen shape with a rounded-rectangle hole punched in it. Fill it
/// with the even-odd rule (`FillStyle(eoFill: true)`) and the hole stays
/// clear while everything around it dims — that is the spotlight.
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

/// The overlay that plays over the real home screen while the tour runs:
/// the dim with its spotlight hole, a white ring around the highlighted
/// element, and the tip card (step count, icon, tip, Back/Next, dots,
/// Skip). Tapping the highlighted element advances, just like Next.
struct VentureMapTourOverlay: View {
    @ObservedObject private var tour = VentureMapTourManager.shared
    /// Frames of the anchored views, in the "tour" coordinate space.
    let anchors: [TourAnchor: CGRect]

    /// The app's green, matching the splash screen.
    private let ventureGreen = Color(red: 0.18, green: 0.41, blue: 0.24)

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let hole = holeRect(for: tour.currentStep.anchor, in: size)
            // The tip card goes on the opposite side from the spotlight, so
            // it never covers what the step is pointing at.
            let cardOnTop = hole.midY > size.height * 0.55
            ZStack {
                // The dim. Its empty tap handler matters: it swallows taps
                // on the dimmed area so they never reach the map below.
                SpotlightShape(hole: hole)
                    .fill(Color.black.opacity(0.55), style: FillStyle(eoFill: true))
                    .contentShape(Rectangle())
                    .onTapGesture { }

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

                VStack {
                    if cardOnTop {
                        tourCard
                        Spacer()
                    } else {
                        Spacer()
                        tourCard
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, cardOnTop ? 60 : 0)
                .padding(.bottom, cardOnTop ? 0 : 32)
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

    private var tourCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Step \(tour.step + 1) of \(tour.steps.count)")
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Skip") { tour.skip() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.35))
                    .clipShape(Capsule())
            }
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Image(systemName: tour.currentStep.icon)
                        .font(.title2)
                    Text(tour.currentStep.label)
                        .font(.caption.weight(.semibold))
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.white)
                .frame(width: 84, height: 68)
                .background(ventureGreen)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                Text(tour.currentStep.tip)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }
            Text("You're on the real screen. Tap the highlighted area or Next to continue.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Button("Back") { tour.back() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ventureGreen)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(ventureGreen, lineWidth: 1.5))
                    .disabled(tour.step == 0)
                    .opacity(tour.step == 0 ? 0.4 : 1)
                Button(tour.isLastStep ? "Finish" : "Next") { tour.advance() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(ventureGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            HStack(spacing: 8) {
                ForEach(tour.steps) { item in
                    Circle()
                        .fill(item.id == tour.step ? ventureGreen : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(20)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 6)
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
