import XCTest
@testable import VentureMap

/// Unit tests for the tour manager — the first tests in the project.
///
/// The manager is the ideal place to start: it is pure logic (which step
/// is showing, when the tour is done) with no UI involved, so the tests
/// run fast and need no simulator screen.
///
/// Two things to know about testing this manager:
///
/// - It is a singleton (`VentureMapTourManager.shared`), so state carries
///   between tests. `setUp` and `tearDown` reset it: stop a running tour,
///   then clear both done flags from UserDefaults.
/// - The done flags live in the real UserDefaults. The tests write and
///   clear the tour's own keys only, and always clean up after
///   themselves, so running the tests never leaves the app thinking the
///   tour is done.
///
/// The manager runs on the main actor (the app target sets
/// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`), so the test class is
/// `@MainActor` too — that keeps every call synchronous.
@MainActor
final class VentureMapTourManagerTests: XCTestCase {
    private let doneKey = "venturemap.tourDone.v1"
    private let legacyGuestDoneKey = "venturemap.tourDone.v1.guest"

    private var tour: VentureMapTourManager { .shared }

    override func setUp() {
        super.setUp()
        resetTourState()
    }

    override func tearDown() {
        resetTourState()
        super.tearDown()
    }

    /// Stops any running tour and clears both done flags, so every test
    /// starts from "never seen the tour."
    private func resetTourState() {
        if tour.isShowing {
            tour.skip()
        }
        UserDefaults.standard.removeObject(forKey: doneKey)
        UserDefaults.standard.removeObject(forKey: legacyGuestDoneKey)
    }

    // MARK: - Starting

    func testStartAgainShowsFirstStep() {
        tour.startAgain(isGuest: true)

        XCTAssertTrue(tour.isShowing)
        XCTAssertEqual(tour.step, 0)
        XCTAssertEqual(tour.currentStep.id, 0)
        XCTAssertTrue(tour.isGuest)
    }

    func testStartAgainWorksAfterTourIsDone() {
        tour.startAgain(isGuest: true)
        tour.skip()
        XCTAssertTrue(tour.isDone)

        tour.startAgain(isGuest: false)

        XCTAssertTrue(tour.isShowing)
        XCTAssertEqual(tour.step, 0)
        XCTAssertFalse(tour.isGuest)
    }

    func testStartAutomaticallyShowsTourWhenNotDone() {
        tour.startAutomaticallyIfNeeded(isGuest: true)

        XCTAssertTrue(tour.isShowing)
        XCTAssertEqual(tour.step, 0)
    }

    func testStartAutomaticallyDoesNothingWhenDone() {
        UserDefaults.standard.set(true, forKey: doneKey)

        tour.startAutomaticallyIfNeeded(isGuest: true)

        XCTAssertFalse(tour.isShowing)
    }

    func testStartAutomaticallyDoesNothingWhileAlreadyShowing() {
        tour.startAgain(isGuest: true)
        tour.advance()
        XCTAssertEqual(tour.step, 1)

        // A second automatic start must not restart the tour mid-walk,
        // and must not flip the guest copy under the user's feet.
        tour.startAutomaticallyIfNeeded(isGuest: false)

        XCTAssertEqual(tour.step, 1)
        XCTAssertTrue(tour.isShowing)
        XCTAssertTrue(tour.isGuest)
    }

    // MARK: - Walking and finishing

    func testAdvanceWalksEveryStepThenFinishes() {
        tour.startAgain(isGuest: true)

        XCTAssertEqual(tour.steps.count, 5)
        XCTAssertFalse(tour.isLastStep)

        tour.advance()
        XCTAssertEqual(tour.step, 1)
        tour.advance()
        XCTAssertEqual(tour.step, 2)
        tour.advance()
        XCTAssertEqual(tour.step, 3)
        tour.advance()
        XCTAssertEqual(tour.step, 4)
        XCTAssertTrue(tour.isLastStep)

        // Advancing past the last step finishes the tour.
        tour.advance()
        XCTAssertFalse(tour.isShowing)
        XCTAssertTrue(tour.isDone)
    }

    func testSkipFinishesAndMarksDone() {
        tour.startAgain(isGuest: true)
        tour.advance()
        XCTAssertEqual(tour.step, 1)

        tour.skip()

        XCTAssertFalse(tour.isShowing)
        XCTAssertTrue(tour.isDone)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: doneKey))
    }

    // MARK: - Done flags

    func testLegacyGuestKeyCountsAsDone() {
        UserDefaults.standard.set(true, forKey: legacyGuestDoneKey)

        XCTAssertTrue(tour.isDone)

        tour.startAutomaticallyIfNeeded(isGuest: true)
        XCTAssertFalse(tour.isShowing)
    }

    func testDoneFlagIsSharedAcrossGuestAndSignedIn() {
        // A guest finishes the tour...
        tour.startAgain(isGuest: true)
        tour.skip()
        XCTAssertTrue(tour.isDone)

        // ...so a signed-in user never sees it again either.
        tour.startAutomaticallyIfNeeded(isGuest: false)
        XCTAssertFalse(tour.isShowing)
    }

    // MARK: - Copy

    func testGuestAndSignedInCopyDifferWhereTheyShould() {
        tour.startAgain(isGuest: true)
        let guestTips = tour.steps.map(\.tip)

        tour.startAgain(isGuest: false)
        let signedInTips = tour.steps.map(\.tip)

        // Steps 1, 3, and 5 adapt; steps 2 and 4 are the same for everyone.
        XCTAssertNotEqual(guestTips[0], signedInTips[0])
        XCTAssertEqual(guestTips[1], signedInTips[1])
        XCTAssertNotEqual(guestTips[2], signedInTips[2])
        XCTAssertEqual(guestTips[3], signedInTips[3])
        XCTAssertNotEqual(guestTips[4], signedInTips[4])

        // The guest map step mentions practice; the signed-in one does not.
        XCTAssertTrue(guestTips[0].contains("practice"))
        XCTAssertFalse(signedInTips[0].contains("practice"))
    }

    func testStepOneCopyDoesNotPromisePanning() {
        // The overlay eats every touch, so the tour cannot promise pan and
        // zoom. Both versions of the first tip must say what the tour
        // actually allows: tap anywhere to keep going.
        tour.startAgain(isGuest: true)
        XCTAssertFalse(tour.steps[0].tip.contains("Pan and zoom"))
        XCTAssertTrue(tour.steps[0].tip.contains("Tap anywhere"))

        tour.startAgain(isGuest: false)
        XCTAssertFalse(tour.steps[0].tip.contains("Pan and zoom"))
        XCTAssertTrue(tour.steps[0].tip.contains("Tap anywhere"))
    }
}
