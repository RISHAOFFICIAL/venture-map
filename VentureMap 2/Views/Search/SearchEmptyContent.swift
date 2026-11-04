import SwiftUI

/// What `LocationSearchView` shows when the typed query has zero matches —
/// an empty state with a call to action to log a new event at that place
/// instead.
struct SearchEmptyContent: View {
    let query: String
    let onLogEvent: () -> Void

    var body: some View {
        VStack(spacing: 17) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.title)
                .foregroundStyle(.secondary)
                .frame(width: 58, height: 58)
                .background(.secondary.opacity(0.1), in: Circle())

            VStack(spacing: 5) {
                Text("No results for “\(query)”")
                    .font(.headline)
                Text("Check the spelling, or log an event there to add it to your map.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }

            Button("Log event at \(query)") {
                onLogEvent()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 2)

            Spacer()
        }
    }
}
