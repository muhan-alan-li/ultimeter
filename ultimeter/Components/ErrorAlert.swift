//
//  ErrorAlert.swift
//  ultimeter
//

import SwiftUI

extension View {
    /// Shows one alert for a failed screen action.
    /// Every screen uses this. No screen writes its own alert block.
    func errorAlert(_ error: Binding<AppError?>) -> some View {
        alert(
            "Action Failed",
            isPresented: Binding(
                get: { error.wrappedValue != nil },
                set: { if !$0 { error.wrappedValue = nil } }
            ),
            presenting: error.wrappedValue
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { failure in
            Text(failure.errorDescription ?? "The action failed. Try again.")
        }
    }
}
