import SwiftUI

/// A `TextField` preconfigured with sensible keyboard/capitalization
/// defaults, so `AddEventView`'s form doesn't repeat the same three
/// modifiers on every field.
struct EventTextField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
            .submitLabel(.next)
    }
}
