//
//  ScreenModel.swift
//  ultimeter
//

import Foundation
import Observation
import SwiftUI

/// A screen view model. It needs the app repositories.
///
/// A view reads `error` and calls the intent methods.
/// The view connects the repositories with `.connect(model)`.
@MainActor
protocol ScreenModel: AnyObject {
    /// The repositories. `connect` sets this one time.
    var dependencies: AppDependencies? { get set }

    /// The last failure of a screen action. The view shows it.
    var error: AppError? { get set }
}

extension ScreenModel {
    /// The connected repositories. Traps when the view did not connect.
    var deps: AppDependencies {
        guard let dependencies else {
            preconditionFailure("\(Self.self) is not connected. Add .connect(model).")
        }
        return dependencies
    }

    /// Connects the repositories one time.
    func connect(_ dependencies: AppDependencies) {
        guard self.dependencies == nil else { return }
        self.dependencies = dependencies
    }

    /// Runs one action. Stores the failure for the alert.
    /// Returns true when the action succeeded.
    @discardableResult
    func attempt(_ action: () throws -> Void) -> Bool {
        do {
            try action()
            return true
        } catch let failure as AppError {
            error = failure
            return false
        } catch {
            self.error = .unexpected(error.localizedDescription)
            return false
        }
    }
}

/// Connects one screen view model to the app dependencies.
/// Wires at render and again at appear. The render wiring covers actions
/// the view itself fires in its own `onAppear`, which runs before this
/// modifier's `onAppear`. The appear wiring covers taps even if a render
/// pass is skipped. `connect` keeps the first wiring, so both are safe.
private struct DependencyConnector<Model: ScreenModel>: ViewModifier {
    @Environment(AppDependencies.self) private var dependencies
    let model: Model

    func body(content: Content) -> some View {
        model.connect(dependencies)
        return content.onAppear { model.connect(dependencies) }
    }
}

extension View {
    /// Gives one screen view model its repositories.
    /// A view cannot read the environment in its `init`. This closes the gap.
    func connect<Model: ScreenModel>(_ model: Model) -> some View {
        modifier(DependencyConnector(model: model))
    }
}
