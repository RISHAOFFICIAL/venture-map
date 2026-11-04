import SwiftUI
import MapKit

/// The main app screen after signing in (or entering as a guest): a
/// full-screen map with a header, a reach-stats card, and every sheet the
/// home screen can present.
///
/// This is the single best file in the project for seeing how a non-trivial
/// SwiftUI screen is put together, so it's worth reading top to bottom:
///
/// - **Custom `init`**: Most SwiftUI views get a free memberwise
///   initializer, but this one writes its own because `businesses`,
///   `selectedBusinessID`, `events`, and `accountName` all need to start with
///   *different* values depending on `isGuest`. Inside a custom init, you
///   must set `@State` properties using the special `_propertyName =
///   State(initialValue: ...)` form (not `propertyName = ...`), because at
///   this point you're configuring the property wrapper itself, before the
///   view has "started."
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
    @State private var events: [CommunityEvent]
    // The organization name the person signed in or signed up with.
    @AppStorage("accountOrganization") private var accountName = ""
    @State private var organizationFocus = "Technology-focused outreach"
    @State private var businesses: [Business]
    @State private var selectedBusinessID: UUID
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
    @State private var showsTutorial = false
    // Powers the "center on me" location button above the reach card.
    @State private var userLocationProvider
 = UserLocationProvider()

    init(isGuest: Bool, onRequireSignIn: @escaping () -> Void, onRequireSignUp: @escaping () -> Void) {
        self.isGuest = isGuest
        self.onRequireSignIn = onRequireSignIn
        self.onRequireSignUp = onRequireSignUp
        // Guests get a small, clearly-labeled practice dataset instead of the same
        // data a signed-in account would see, so practice mode never looks "real."
        let businesses = isGuest ? Business.practiceBusinesses : Business.sampleBusinesses
        _businesses = State(initialValue: businesses)
        _selectedBusinessID = State(initialValue: businesses[0].id)
        _events = State(initialValue: isGuest ? CommunityEvent.practiceEvents : CommunityEvent.sampleEvents)
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
        .sheet(isPresented: $showsAddEvent) {
            AddEventView(
                initialLocation: initialLocation,
                businessID: selectedBusinessID,
                allowsSaving: !isGuest,
                onRequireSignIn: onRequireSignIn
            ) { event in
                events.append(event)
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: event.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                    )
                )
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
                    showsAddEvent = true
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
                onSelectGuestFeature: openGuestFeature
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
        .fullScreenCover(isPresented: $showsTutorial) {
            GuestTutorialView(onFinish: { showsTutorial = false })
        }
        .onAppear {
            if isGuest {
                showsTutorial = true
            }
        }
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
        }
    }

    private var filteredEvents: [CommunityEvent] {
        events.filter { event in
            event.businessID == selectedBusinessID
                && timeRange.includes(event.date)
                && (selectedEventType == nil || event.eventType == selectedEventType)
        }
    }

    // Finding-then-replacing by `id` (rather than mutating in place) is the
    // standard way to "edit" one value inside an array of structs: since
    // `CommunityEvent` is a value type, there's no shared reference to
    // update — you must locate the matching element's index and overwrite it.
    private func updateEvent(_ updatedEvent: CommunityEvent) {
        guard let index = events.firstIndex(where: { $0.id == updatedEvent.id }) else { return }
        events[index] = updatedEvent
    }
}
