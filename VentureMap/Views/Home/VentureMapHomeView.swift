import SwiftUI
import MapKit
import SwiftData

/// The main app screen after signing in (or entering as a guest): a
/// full-screen map with a header, a reach-stats card, and every sheet the
/// home screen can present.
///
/// This is the single best file in the project for seeing how a non-trivial
/// SwiftUI screen is put together, so it's worth reading top to bottom:
///
/// - **Custom `init`**: Most SwiftUI views get a free memberwise
///   initializer, but this one writes its own because `businesses`,
///   `selectedBusinessID`, `guestEvents`, and `accountName` all need to start with
///   *different* values depending on `isGuest`. Inside a custom init, you
///   must set `@State` properties using the special `_propertyName =
///   State(initialValue: ...)` form (not `propertyName = ...`), because at
///   this point you're configuring the property wrapper itself, before the
///   view has "started."
/// - **Saved events vs practice events**: a signed-in account reads its
///   events from the SwiftData store (`@Query`), so adds and edits survive
///   app relaunches. A guest never touches the store: practice events live
///   only in the in-memory `guestEvents` array, and disappear when the app
///   closes. The computed `events` property below is the single place that
///   picks which list the rest of the screen sees.
/// - **One `@State` per piece of mutable UI state**: every sheet
///   (`showsAddEvent`, `showsSearch`, `showsProfile`, ...) is just a `Bool`
///   that a `.sheet(isPresented:)` watches. Setting it to `true` is all it
///   takes to present something — no manual presentation/dismissal API.
/// - **`.sheet(item:)`** (used for `detailEvent` and `fullListLocation`) is
///   the optional-driven sibling of `.sheet(isPresented:)`: the sheet shows
///   automatically whenever the bound optional becomes non-nil, and the
///   non-nil value is handed straight into the sheet's content closure.
/// - **View modifier chaining**: body is one `OutreachMap` with a long chain
///   of `.sheet`, `.overlay`, `.safeAreaInset`, etc. attached. Each modifier
///   wraps the view before it, building up behavior layer by layer, in the
///   order they're written.
/// - **Computed `filteredEvents`** re-runs on every redraw, applying the
///   current business/time-range/event-type filters — there's no separate
///   "filtered list" to keep in sync by hand.
struct VentureMapHomeView: View {
    let isGuest: Bool
    let onRequireSignIn: () -> Void
    let onRequireSignUp: () -> Void
    // The SwiftData context, provided by `MyApp`. Writes (insert, save) go
    // through here; reads come from `storedEvents` below.
    @Environment(\.modelContext) private var modelContext
    // Saved events for a signed-in account, newest first. `@Query` keeps
    // this list live: inserts and edits in the store re-run `body` on their own.
    @Query(sort: \CommunityEvent.date, order: .reverse) private var storedEvents: [CommunityEvent]
    // Practice events for a guest, kept only in memory. Guests never write
    // to the saved store.
    @State private var guestEvents: [CommunityEvent]

    /// The events this screen shows: saved events for a signed-in account,
    /// in-memory practice events for a guest.
    private var events: [CommunityEvent] {
        isGuest ? guestEvents : storedEvents
    }
    // The organization name the person signed in or signed up with.
    @AppStorage("accountOrganization") private var accountName = ""
    @State private var organizationFocus = "Technology-focused outreach"
    @State private var businesses: [Business]
    // The active business, or nil when the account has none yet (sample
    // data off, user hasn't added a business). The header picker, the
    // profile list, and the add-event flow all handle nil — see
    // `HomeHeader`, `ProfileView`, and the add-event sheet below.
    @State private var selectedBusinessID: UUID?
    @State private var cameraPosition = MapCameraPosition.region(CommunityEvent.detroitRegion)
    @State private var selectedLocation: SelectedLocation?
    @State private var timeRange: TimeRange = .ninetyDays
    @State private var selectedEventType: EventType?
    @State private var showsAddEvent = false
    @State private var showsSearch = false
    @State private var showsProfile = false
    @State private var showsReachOverview = false
    @State private var initialLocation = ""
    @State private var detailEvent: CommunityEvent?
    @State private var fullListLocation: SelectedLocation?
    // The guided tour (see `VentureMapTour.swift`): spotlights the real
    // home-screen elements instead of the old swipeable word pages.
    @ObservedObject private var tour = VentureMapTourManager.shared
    // Frames of the tour's anchor views, reported up through
    // `TourFramePreferenceKey` in the window's global coordinate space.
    @State private var tourAnchors: [TourAnchor: CGRect] = [:]
    // True while the callout on screen is one the tour opened itself, so
    // finishing the tour can close it again.
    @State private var tourOpenedCallout = false
    // Powers the "center on me" location button above the reach card.
    @State private var userLocationProvider
 = UserLocationProvider()

    init(isGuest: Bool, onRequireSignIn: @escaping () -> Void, onRequireSignUp: @escaping () -> Void) {
        self.isGuest = isGuest
        self.onRequireSignIn = onRequireSignIn
        self.onRequireSignUp = onRequireSignUp
        // Guests get a small, clearly-labeled practice dataset instead of the same
        // data a signed-in account would see, so practice mode never looks "real."
        // Guests always start fresh: practice mode saves nothing.
        if isGuest {
            _businesses = State(initialValue: Business.practiceBusinesses)
            _selectedBusinessID = State(initialValue: Business.practiceBusinesses[0].id)
        } else if let saved = BusinessStore.load() {
            // A returning account restores its own businesses — including
            // ones added in the app, which used to vanish on restart
            // because nothing saved them. With sample data off, any saved
            // sample businesses are dropped: they belong to the demo,
            // not to this account.
            var businesses = saved.businesses
            if !DemoData.isEnabled {
                let sampleIDs = Set(Business.sampleBusinesses.map(\.id))
                businesses.removeAll { sampleIDs.contains($0.id) }
            }
            let selectedID = businesses.contains(where: { $0.id == saved.selectedID })
                ? saved.selectedID
                : businesses.first?.id
            _businesses = State(initialValue: businesses)
            _selectedBusinessID = State(initialValue: selectedID)
        } else if DemoData.isEnabled {
            // First launch with the demo switch on: the class sample
            // businesses, and the sample events are seeded into the
            // SwiftData store below.
            _businesses = State(initialValue: Business.sampleBusinesses)
            _selectedBusinessID = State(initialValue: Business.sampleBusinesses[0].id)
        } else {
            // First launch with the demo switch off (shipping): a new
            // account starts with no businesses at all. The header, the
            // profile, and the tour all guide the user to add their
            // first one.
            _businesses = State(initialValue: [])
            _selectedBusinessID = State(initialValue: nil)
        }
        _guestEvents = State(initialValue: CommunityEvent.practiceEvents)
    }

    var body: some View {
        OutreachMap(
            events: filteredEvents,
            cameraPosition: $cameraPosition,
            selectedLocation: $selectedLocation,
            onSelectEvent: { event in detailEvent = event },
            onShowAllEvents: { location in fullListLocation = location }
        )
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom) {
            // Reserving this space (rather than floating UI over the map) keeps
            // MapKit's required Apple logo and legal link clear of our custom UI, per HIG.
            VStack(spacing: 10) {
                // The location button: right-aligned, right above the reach card.
                HStack {
                    Spacer()
                    Button {
                        centerOnUserLocation()
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundStyle(.primary)
                            .padding(12)
                            .background(.regularMaterial, in: Circle())
                            .shadow(radius: 2)
                    }
                    .accessibilityLabel("Center map on my location")
                }

                Button {
                    showsReachOverview = true
                } label: {
                    ReachCard(events: filteredEvents)
                }
                .buttonStyle(.plain)
                .tourAnchor(.reachCard)
                .accessibilityLabel("Open your reach overview")
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .overlay(alignment: .top) {
            VStack(spacing: 8) {
                HomeHeader(
                    showsSearch: $showsSearch,
                    showsAddEvent: $showsAddEvent,
                    showsProfile: $showsProfile,
                    timeRange: $timeRange,
                    selectedEventType: $selectedEventType,
                    businesses: businesses,
                    selectedBusinessID: $selectedBusinessID
                )

                if isGuest {
                    PracticeModeBanner()
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
        }
        .onPreferenceChange(TourFramePreferenceKey.self) { frames in
            tourAnchors = frames
        }
        // The tour overlay sits above the map, header, and reach card, so
        // its dim covers the real screen while the spotlight hole and tip
        // card stay on top.
        .overlay {
            if tour.isShowing {
                VentureMapTourOverlay(anchors: tourAnchors)
            }
        }
        .sheet(isPresented: $showsAddEvent) {
            Group {
                if let businessID = selectedBusinessID {
                    AddEventView(
                        initialLocation: initialLocation,
                        businessID: businessID,
                        allowsSaving: !isGuest,
                        onRequireSignIn: onRequireSignIn
                    ) { event in
                        if isGuest {
                            guestEvents.append(event)
                        } else {
                            modelContext.insert(event)
                            try? modelContext.save()
                        }
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: event.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                            )
                        )
                    }
                } else {
                    // No business to attach the event to (sample data off,
                    // user hasn't added one yet). The + button and the
                    // search "add at place" row both route to the profile
                    // first, so this is normally unreachable — but the
                    // sheet can be opened from more than one place, so
                    // the prompt exists rather than the form opening with
                    // nowhere to save to.
                    AddBusinessFirstView {
                        showsAddEvent = false
                        showsProfile = true
                    }
                }
            }
            .presentationDetents([.fraction(0.78)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showsSearch) {
            LocationSearchView(
                events: filteredEvents,
                onSelectEvent: { event in
                    showsSearch = false
                    selectedLocation = SelectedLocation(location: event.location)
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: event.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                        )
                    )
                },
                onAddAtPlace: { place in
                    initialLocation = place
                    showsSearch = false
                    if selectedBusinessID == nil {
                        // No business yet: send the user to add one
                        // first instead of opening a form with nowhere
                        // to save to.
                        showsProfile = true
                    } else {
                        showsAddEvent = true
                    }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showsProfile) {
            ProfileView(
                accountName: $accountName,
                organizationFocus: $organizationFocus,
                businesses: $businesses,
                selectedBusinessID: $selectedBusinessID,
                allowsSaving: !isGuest,
                onRequireSignIn: onRequireSignIn,
                onRequireSignUp: onRequireSignUp,
                onSelectGuestFeature: openGuestFeature,
                onReplayTour: {
                    tour.startAgain(isGuest: isGuest)
                }
            )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showsReachOverview) {
            ReachOverviewView(events: events, onUpdateEvent: updateEvent)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $detailEvent) { event in
            EventDetailView(event: event, onSave: updateEvent)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $fullListLocation) { selection in
            LocationEventsView(
                location: selection.location,
                events: events.filter { $0.location == selection.location },
                onUpdateEvent: updateEvent
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            // The tour shows the first time anyone enters the map, guest
            // or signed-in — a new account has never seen the map either.
            // The manager itself decides whether it has already been seen.
            tour.startAutomaticallyIfNeeded(isGuest: isGuest)
        }
        .onChange(of: tour.step) { _, _ in
            prepareTourStep()
        }
        .onChange(of: tour.isShowing) { _, isShowing in
            if !isShowing {
                clearTourCallout()
            }
        }
        // Keep the signed-in account's businesses saved, so a business
        // added in the app is still there after a relaunch. Guests never
        // save: practice mode always starts fresh.
        .onChange(of: businesses) { _, _ in
            saveBusinessesIfSignedIn()
        }
        .onChange(of: selectedBusinessID) { _, _ in
            saveBusinessesIfSignedIn()
        }
        .task {
            seedSampleEventsIfNeeded()
        }
    }

    /// First launch for a signed-in account starts with the sample events,
    /// so the map is never empty — but only while the demo switch is on
    /// (see `DemoData`). With the switch off, a new account starts with
    /// an empty store and adds its own events. This only ever inserts
    /// once: after seeding, the store is no longer empty, so later
    /// launches skip it. Guests never reach this — their practice events
    /// stay in memory only.
    private func seedSampleEventsIfNeeded() {
        guard !isGuest, DemoData.isEnabled else { return }
        let descriptor = FetchDescriptor<CommunityEvent>()
        guard let existing = try? modelContext.fetch(descriptor), existing.isEmpty else { return }
        for event in CommunityEvent.sampleEvents {
            modelContext.insert(event)
        }
        try? modelContext.save()
    }

    /// Saves the signed-in account's businesses (and which one is
    /// active) so they survive app relaunches. Guests never save:
    /// practice mode always starts fresh.
    private func saveBusinessesIfSignedIn() {
        guard !isGuest else { return }
        BusinessStore.save(businesses: businesses, selectedID: selectedBusinessID)
    }

    /// Centers the map on the user's current location with an animation.
    /// The provider asks for location permission first if needed; when the
    /// coordinate arrives, the camera moves to it.
    private func centerOnUserLocation() {
        userLocationProvider.requestLocation { coordinate in
            withAnimation {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                    )
                )
            }
        }
    }

    /// Takes a guest from the profile's "What you can do" list to the real
    /// part of the app that row describes. The profile closes itself first.
    private func openGuestFeature(_ feature: GuestFeature) {
        switch feature {
        case .exploreMap:
            // Just land on the map; the profile has already closed.
            break
        case .addEvent:
            initialLocation = ""
            showsAddEvent = true
        case .checkReach:
            showsReachOverview = true
        case .saveProgress:
            onRequireSignUp()
        case .replayTour:
            tour.startAgain(isGuest: true)
        }
    }

    /// Sets the real screen up for the tour's current step. Only the pin
    /// step needs setup: it opens the first event's callout so the tour can
    /// spotlight a real callout, and moves the camera so the callout is on
    /// screen. If the filters hide every event, there is nothing to open
    /// and the step falls back to spotlighting the map. Moving past the pin
    /// step closes the callout again, so it doesn't sit dimmed in the
    /// middle of the screen for the rest of the tour.
    private func prepareTourStep() {
        guard tour.isShowing else { return }
        guard tour.currentStep.anchor == .callout else {
            clearTourCallout()
            return
        }
        guard !tourOpenedCallout else { return }
        guard let first = filteredEvents.first else { return }
        tourOpenedCallout = true
        withAnimation {
            selectedLocation = SelectedLocation(location: first.location)
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: first.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                )
            )
        }
    }

    /// Closes the callout the tour opened, if it opened one. Runs when the
    /// tour moves past the pin step, finishes, or is skipped, so the guest
    /// lands back on a clean map.
    private func clearTourCallout() {
        guard tourOpenedCallout else { return }
        tourOpenedCallout = false
        selectedLocation = nil
    }

    private var filteredEvents: [CommunityEvent] {
        events.filter { event in
            event.businessID == selectedBusinessID
                && timeRange.includes(event.date)
                && (selectedEventType == nil || event.eventType == selectedEventType)
        }
    }

    // The edit sheets hand back a detached copy (see `CommunityEvent`), so
    // saving means finding the real event with the same `id` and copying the
    // edited values onto it. For a guest, the "real" event lives in the
    // in-memory practice array; for a signed-in account, it lives in the
    // SwiftData store, and `save()` writes the change to disk.
    private func updateEvent(_ updatedEvent: CommunityEvent) {
        if isGuest {
            guard let index = guestEvents.firstIndex(where: { $0.id == updatedEvent.id }) else { return }
            guestEvents[index] = updatedEvent
            return
        }
        guard let stored = storedEvents.first(where: { $0.id == updatedEvent.id }) else { return }
        stored.update(from: updatedEvent)
        try? modelContext.save()
    }
}

/// Saves and loads the signed-in account's businesses list (and which
/// business is active) as JSON in UserDefaults.
///
/// Why this exists: events live in the SwiftData store and survive
/// relaunches, but the businesses list used to live only in `@State` —
/// so a business added in the app vanished on restart, and its events
/// became invisible (nothing in the list matched their business id
/// anymore). Saving the list next to the store keeps the two in step.
///
/// The keys are namespaced (`venturemap.*`) so they never collide with
/// the auth keys (`accountOrganization`, `staysSignedIn`, ...).
private enum BusinessStore {
    private static let businessesKey = "venturemap.savedBusinesses"
    private static let selectedIDKey = "venturemap.selectedBusinessID"

    /// Returns the saved businesses and the saved active business, or
    /// nil when nothing was ever saved (a first launch).
    static func load() -> (businesses: [Business], selectedID: UUID?)? {
        guard let data = UserDefaults.standard.data(forKey: businessesKey),
              let businesses = try? JSONDecoder().decode([Business].self, from: data)
        else { return nil }
        let selectedID = UserDefaults.standard.string(forKey: selectedIDKey)
            .flatMap(UUID.init(uuidString:))
        return (businesses, selectedID)
    }

    static func save(businesses: [Business], selectedID: UUID?) {
        if let data = try? JSONEncoder().encode(businesses) {
            UserDefaults.standard.set(data, forKey: businessesKey)
        }
        UserDefaults.standard.set(selectedID?.uuidString, forKey: selectedIDKey)
    }
}

/// Shown when the add-event sheet opens with no business to attach the
/// event to (sample data off, user hasn't added a business yet). The +
/// button and the search "add at place" row both route to the profile
/// first, so this is normally unreachable — but the sheet can be opened
/// from more than one place, so the prompt exists rather than the form
/// opening with nowhere to save to.
private struct AddBusinessFirstView: View {
    @Environment(\.dismiss) private var dismiss
    let onAddBusiness: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "building.2")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Add your first business")
                    .font(.headline)
                Text("Events belong to a business. Add yours first, then you can start logging events.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Add a business") {
                    onAddBusiness()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Add Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Cancel")
                }
            }
        }
    }
}
