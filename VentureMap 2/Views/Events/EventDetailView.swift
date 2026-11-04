import SwiftUI

/// The sheet shown when tapping an event — displays `EventInformation` in
/// read-only mode, with a pencil button that flips it into editing mode and
/// then saves/commits the change.
///
/// `@State private var event: CommunityEvent`, initialized from the `event`
/// passed into `init`, is a **local, editable copy**. Nothing written here
/// changes the original list back in `VentureMapHomeView` until `onSave` is
/// explicitly called — this is what lets someone open the edit form, make
/// changes, and still cancel out (by dismissing) without those changes ever
/// taking effect.
struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var event: CommunityEvent
    @State private var isEditing = false
    let onSave: (CommunityEvent) -> Void

    init(event: CommunityEvent, onSave: @escaping (CommunityEvent) -> Void) {
        _event = State(initialValue: event)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    EventInformation(event: $event, isEditing: isEditing)
                }

                if !isEditing {
                    Section {
                        Label("Tap the pencil to edit this event.", systemImage: "pencil")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(event.location)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if isEditing {
                            event.category = event.eventType.category
                            onSave(event)
                            isEditing = false
                        } else {
                            isEditing = true
                        }
                    } label: {
                        Image(systemName: isEditing ? "checkmark" : "pencil")
                    }
                    .accessibilityLabel(isEditing ? "Confirm event changes" : "Edit event")
                }
            }
        }
    }
}
