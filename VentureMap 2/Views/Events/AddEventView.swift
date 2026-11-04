import SwiftUI
import MapKit

/// The "log a new event" form, presented as a sheet from the home screen's
/// `+` button.
///
/// This is one of the more advanced views in the app — a good one to study
/// once the simpler views make sense. Highlights:
///
/// - **`.onChange(of:)`**: several fields "sanitize themselves" as you type
///   — e.g. `phoneNumber` strips non-digits and caps the length at 10,
///   `email` strips whitespace. Each `.onChange` runs right after the bound
///   value changes, letting the view immediately correct it.
/// - **`.task(id: location)`**: unlike a plain `.task { }` (which runs once
///   when the view appears), `.task(id:)` re-runs its body *every time* the
///   `id` value changes — here, every time `location` changes, it restarts
///   `updateAddressSuggestions()` and cancels any search already in flight.
/// - **Debouncing**: `try? await Task.sleep(for: .milliseconds(300))`
///   followed by `guard !Task.isCancelled else { return }` is how this view
///   avoids firing a network search on every single keystroke — it waits
///   300ms after the last change, and bails out early if the user typed
///   again (and `.task(id:)` cancelled this one) before that time was up.
/// - **`isReadyToSave`**: a computed property combining several checks
///   (non-empty name, valid phone length, `@` in the email, date not in the
///   future) into one `Bool`, used to `.disabled(...)` the save button.
struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var eventName = ""
    @State private var location: String
    @State private var selectedEventType: EventType = .communityEvent
    @State private var date = Date()
    @State private var peopleReached = ""
    @State private var pointOfContact = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var addressSuggestions: [AddressLookupResult] = []
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var resolvedLocationName = ""

    let businessID: UUID
    let allowsSaving: Bool
    let onRequireSignIn: () -> Void
    let onSave: (CommunityEvent) -> Void

    init(
        initialLocation: String,
        businessID: UUID,
        allowsSaving: Bool,
        onRequireSignIn: @escaping () -> Void,
        onSave: @escaping (CommunityEvent) -> Void
    ) {
        _location = State(initialValue: initialLocation)
        self.businessID = businessID
        self.allowsSaving = allowsSaving
        self.onRequireSignIn = onRequireSignIn
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 4) {
                        Text("*")
                            .foregroundStyle(.red)
                        Text("Required")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    EventTextField(title: "Name of Event *", text: $eventName)
                        .onChange(of: eventName) { _, newValue in
                            eventName = nameCharacters(in: newValue)
                        }
                    EventTextField(title: "Location *", text: $location)
                        .onChange(of: location) { _, newValue in
                            if newValue != resolvedLocationName {
                                selectedCoordinate = nil
                            }
                        }

                    if !addressSuggestions.isEmpty {
                        Section("Map suggestions") {
                            ForEach(addressSuggestions) { suggestion in
                                Button {
                                    resolvedLocationName = suggestion.name
                                    location = suggestion.name
                                    selectedCoordinate = suggestion.coordinate
                                    addressSuggestions = []
                                } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(suggestion.name)
                                            .foregroundStyle(.primary)
                                        Text(suggestion.address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    Picker("Event Type", selection: $selectedEventType) {
                        ForEach(EventType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    DatePicker("Date/Time *", selection: $date, in: ...Date.now)
                    EventTextField(title: "# of Attendees", text: $peopleReached, keyboardType: .numberPad)
                        .onChange(of: peopleReached) { _, newValue in
                            peopleReached = String(newValue.filter(\.isNumber))
                        }
                    EventTextField(title: "Point of Contact *", text: $pointOfContact)
                        .onChange(of: pointOfContact) { _, newValue in
                            pointOfContact = nameCharacters(in: newValue)
                        }
                    EventTextField(title: "Phone Number *", text: $phoneNumber, keyboardType: .phonePad)
                        .onChange(of: phoneNumber) { _, newValue in
                            phoneNumber = String(newValue.filter(\.isNumber).prefix(10))
                        }
                    EventTextField(title: "Email *", text: $email, keyboardType: .emailAddress)
                        .onChange(of: email) { _, newValue in
                            email = newValue.filter { !$0.isWhitespace }
                        }
                }
            }
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

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        guard allowsSaving else {
                            dismiss()
                            onRequireSignIn()
                            return
                        }

                        let place = location.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(
                            CommunityEvent(
                                name: eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? selectedEventType.title : eventName,
                                businessID: businessID,
                                neighborhood: place.isEmpty ? "New location" : place,
                                location: place.isEmpty ? "Location to refine" : place,
                                peopleReached: Int(peopleReached) ?? 0,
                                category: selectedEventType.category,
                                eventType: selectedEventType,
                                date: date,
                                coordinate: selectedCoordinate ?? CommunityEvent.nextCoordinate,
                                pointOfContact: pointOfContact,
                                phoneNumber: phoneNumber,
                                email: email
                            )
                        )
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .accessibilityLabel(allowsSaving ? "Save event" : "Sign in to save event")
                    .disabled(allowsSaving && (selectedCoordinate == nil || !isReadyToSave))
                }
            }
        }
        .task(id: location) {
            await updateAddressSuggestions()
        }
    }

    private func updateAddressSuggestions() async {
        let query = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 3, query != resolvedLocationName else {
            addressSuggestions = []
            return
        }

        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }

        let request = MKLocalSearch.Request(naturalLanguageQuery: query)
        request.region = CommunityEvent.detroitRegion

        do {
            let response = try await MKLocalSearch(request: request).start()
            addressSuggestions = response.mapItems.prefix(4).compactMap { item in
                let coordinate = item.placemark.coordinate
                guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }
                let name = item.name ?? item.placemark.title ?? query
                return AddressLookupResult(
                    name: name,
                    address: item.placemark.title ?? name,
                    coordinate: coordinate
                )
            }
        } catch {
            addressSuggestions = []
        }
    }

    private var isReadyToSave: Bool {
        !eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !pointOfContact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && phoneNumber.count == 10
            && email.contains("@")
            && date <= .now
    }

    private func nameCharacters(in value: String) -> String {
        value.filter { $0.isLetter || $0.isWhitespace || $0 == "-" || $0 == "'" }
    }
}
