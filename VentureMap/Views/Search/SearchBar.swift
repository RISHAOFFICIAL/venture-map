import SwiftUI

/// The search field row at the top of `LocationSearchView`.
///
/// `var isFocused: FocusState<Bool>.Binding` is an unusual-looking type:
/// `@FocusState` lives in the *parent* view, and its projected binding
/// (`$isSearchFocused`) is passed down here so this child view can both read
/// and set keyboard focus via `.focused(isFocused)` — the same binding
/// pattern as `@Binding`, just for focus specifically.
struct SearchBar: View {
    @Binding var query: String
    var isFocused: FocusState<Bool>.Binding
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search", text: $query)
                    .focused(isFocused)
                    .submitLabel(.search)
                Image(systemName: "mic")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .frame(height: 38)
            .background(.background, in: RoundedRectangle(cornerRadius: 9))

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .frame(width: 32, height: 32)
                    .background(.background, in: Circle())
            }
            .accessibilityLabel("Close search")
        }
        .padding(12)
        .background(.thinMaterial)
    }
}
