import SwiftUI

/// One stat tile ("18 · People reached") in the reach overview's metrics
/// row. Takes already-formatted strings rather than raw numbers, so this
/// view doesn't need to know anything about `CommunityEvent` at all — it
/// just displays whatever text it's given.
struct OverviewMetric: View {
    let value: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
