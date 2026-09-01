//
//  SuggestingPicker.swift
//  ultimeter
//

import SwiftUI

/// A text field that lists matching existing values as the user types.
/// The user taps a value, or keeps the typed text to create a new value.
struct SuggestingPicker: View {
    let title: String
    @Binding var text: String
    let values: [String]

    @FocusState private var isFocused: Bool

    private let maxSuggestions = 5

    init(title: String, text: Binding<String>, values: [String]) {
        self.title = title
        self._text = text
        self.values = values
    }

    /// Up to 5 values that match the typed text.
    /// An empty text matches every value.
    private var suggestions: [String] {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = query.isEmpty
            ? values
            : values.filter { $0.localizedCaseInsensitiveContains(query) }
        return Array(
            matches
                .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
                .prefix(maxSuggestions)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(title, text: $text)
                .focused($isFocused)
            if isFocused && !suggestions.isEmpty {
                suggestionCard
            }
        }
    }

    /// The dropdown card of tappable values.
    private var suggestionCard: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(suggestions, id: \.self) { suggestion in
                Button {
                    text = suggestion
                    isFocused = false
                } label: {
                    Text(suggestion)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 10)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    Form {
        SuggestingPicker(
            title: "Opponent Name",
            text: .constant("Ra"),
            values: ["Raiders", "Rivets", "Comets"]
        )
    }
}
