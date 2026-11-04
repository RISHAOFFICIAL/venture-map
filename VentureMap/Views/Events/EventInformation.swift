import SwiftUI

/// Renders either an editable form or a read-only summary of one event,
/// depending on `isEditing`. Used inside `EventDetailView`.
///
/// `@Binding var event: CommunityEvent` means this view can both read *and
/// write* the event living in its parent — every `TextField("", text:
/// $event.name)` below edits a single property through that same binding,
/// so changes show up immediately in the parent without any extra plumbing.
struct EventInformation: View {
    @Binding var event: CommunityEvent
    let isEditing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            if isEditing {
                EditDetailRow(title: "Name") {
                    TextField("", text: $event.name)
                }
                EditDetailRow(title: "Location") {
                    TextField("", text: $event.location)
                }
                EditDetailRow(title: "Neighborhood") {
                    TextField("", text: $event.neighborhood)
                }
                EditDetailRow(title: "Event Type") {
                    Picker("", selection: $event.eventType) {
                        ForEach(EventType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                }
                EditDetailRow(title: "Date/Time") {
                    DatePicker("", selection: $event.date, in: ...Date.now)
                        .labelsHidden()
                }
                EditDetailRow(title: "People Reached") {
                    TextField("", value: $event.peopleReached, format: .number)
                        .keyboardType(.numberPad)
                }
                EditDetailRow(title: "Point of Contact") {
                    TextField("", text: $event.pointOfContact)
                }
                EditDetailRow(title: "Phone Number") {
                    TextField("", text: $event.phoneNumber)
                        .keyboardType(.phonePad)
                }
                EditDetailRow(title: "Email") {
                    TextField("", text: $event.email)
                        .keyboardType(.emailAddress)
                }
            } else {
                Text(event.name)
                    .font(.headline)
                Text(event.location)
                    .font(.headline)
                Text(event.neighborhood)
                    .font(.subheadline)
                DetailRow(title: "Event Type", value: event.eventType.title)
                DetailRow(title: "Date/Time", value: event.date.formatted(.dateTime.month(.abbreviated).day().year().hour().minute()))
                DetailRow(title: "People reached", value: event.peopleReached.formatted())
            }
        }
    }
}
