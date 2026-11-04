import SwiftUI

/// A simple "label — value" line, used in read-only mode by
/// `EventInformation` (compare with `EditDetailRow`, its editable
/// counterpart).
struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.caption.weight(.semibold))
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
