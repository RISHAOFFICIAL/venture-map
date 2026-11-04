import SwiftUI

/// One row in a location's event history list (`LocationEventsView`),
/// wrapped entirely in a `Button` so tapping anywhere on the row triggers
/// `onEdit` — a common way to make a whole custom row tappable, rather than
/// relying on `List`'s built-in row-selection behavior.
struct EventHistoryRow: View {
    let event: CommunityEvent
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: 8) {
                Text(event.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

            HStack {
                Label(event.eventType.title, systemImage: "calendar")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(event.peopleReached) reached")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.green)
            }

            Text(event.date, format: .dateTime.month(.abbreviated).day().year().hour().minute())
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Label(event.neighborhood, systemImage: "mappin")
                Label("Event details", systemImage: "info.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
