import SwiftUI

/// An alternate, `Form`-based editor for a single event.
///
/// Note: nothing in the app currently presents this view — `EventDetailView`
/// handles editing inline instead. It's a leftover/alternate design, left in
/// place as another example of the "local `@State` copy + `onSave` callback"
/// editing pattern also used by `EventDetailView`.
struct EventEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var event: CommunityEvent

    let onSave: (CommunityEvent) -> Void

    init(event: CommunityEvent, onSave: @escaping (CommunityEvent) -> Void) {
        _event = State(initialValue: event)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Event details") {
                    TextField("Event name", text: $event.name)
                    TextField("Location", text: $event.location)
                    TextField("Neighborhood", text: $event.neighborhood)
                    Picker("Event type", selection: $event.eventType) {
                        ForEach(EventType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    DatePicker("Date/Time", selection: $event.date)
                    TextField("People reached", value: $event.peopleReached, format: .number)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm changes") {
                        event.category = event.eventType.category
                        onSave(event)
                        dismiss()
                    }
                }
            }
        }
    }
}
