import SwiftUI

/// A label paired with an arbitrary editable control (a `TextField`, a
/// `Picker`, a `DatePicker`...), used throughout `EventInformation`'s editing
/// mode.
///
/// Like `AuthenticationForm`, this is **generic** (`<Content: View>`) and
/// uses `@ViewBuilder` — it doesn't know or care whether `content` is a
/// `TextField` or a `Picker`, only that it's *some* `View`. This lets one row
/// layout be reused for every field type in the edit form.
struct EditDetailRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.caption.weight(.semibold))
                .frame(width: 112, alignment: .leading)
            content
                .multilineTextAlignment(.trailing)
        }
    }
}
