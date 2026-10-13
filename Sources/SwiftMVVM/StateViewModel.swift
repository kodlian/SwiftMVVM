//
//  ViewModel.swift
//  SwiftMVVM
//
//  Created by Jérémy Marchand.
//  Copyright © 2025 Jérémy Marchand. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import SwiftUI

/// A property wrapper type that instantiates an observable view model with dependency injection.
///
/// Similar to `@StateObject`, this property wrapper ensures a single instance
/// of the observable view model is created and retained for the lifetime of the view,
/// using a closure-based initializer.
/// Additionally, it provides safe dependency injection by passing the full
/// `EnvironmentValues` to the view model factory closure.
///
/// For example with dependency injection from environment:
///
/// ```swift
/// struct MyView: View {
///     @StateViewModel var viewModel: MyViewModel
///
///     init() {
///         self._viewModel = StateViewModel { env in
///             MyViewModel(
///                 database: env[dependency: DatabaseService.self]!,
///                 network: env[dependency: NetworkService.self]!
///             )
///         }
///     }
/// }
/// ```
///
/// Or use @Injected directly in the ViewModel for less boilerplate:
///
/// ```swift
/// @Observable
/// class MyViewModel {
///    @ObservationIgnored @Injected<NetworkService> var networkService: NetworkService
///    @ObservationIgnored @Injected(\ServiceSuite.service1) var service1: NetworkService
/// }
///
/// struct MyView: View {
///     @StateViewModel var viewModel = MyViewModel()
/// }
/// ```
@propertyWrapper @MainActor
public struct StateViewModel<ViewModel: AnyObject & Observable>: DynamicProperty {
    class LazyRerefence {
        var value: ViewModel?
    }

    @State private var reference = LazyRerefence()
    @Environment(\.self) private var env
    let makeViewModel: (EnvironmentValues) -> ViewModel?

    /// Creates a StateViewModel with a factory closure that receives environment values.
    ///
    /// - Parameter makeViewModel: A closure that creates the view model using environment values.
    ///   Return `nil` to skip creation for now; the closure runs again on the next update.
    public init(makeViewModel: @escaping (EnvironmentValues) -> ViewModel?) {
        self.makeViewModel = makeViewModel
    }

    /// Creates the view model from one optional environment value, waiting while it is `nil`.
    public init<Value>(
        _ keyPath: KeyPath<EnvironmentValues, Value?>,
        makeViewModel: @escaping (Value) -> ViewModel
    ) {
        self.makeViewModel = { env in
            env[keyPath: keyPath].map(makeViewModel)
        }
    }

    /// Creates the view model from one optional environment value and the environment, waiting while the value is `nil`.
    public init<Value>(
        _ keyPath: KeyPath<EnvironmentValues, Value?>,
        makeViewModel: @escaping (Value, EnvironmentValues) -> ViewModel
    ) {
        self.makeViewModel = { env in
            env[keyPath: keyPath].map { makeViewModel($0, env) }
        }
    }

    /// Creates a StateViewModel with a simple autoclosure that creates the view model.
    ///
    /// This initializer is convenient when the view model doesn't need environment values.
    ///
    /// - Parameter wrappedValue: An autoclosure that creates the view model
    public init(wrappedValue: @autoclosure @escaping () -> ViewModel) {
        self.makeViewModel = { _ in
            wrappedValue()
        }
    }

    /// The view model instance.
    ///
    /// Accessing this property before the view is rendered and its factory returned a view model will cause a runtime error.
    public var wrappedValue: ViewModel {
        precondition(
            reference.value != nil,
            "StateViewModel should be accessed only after the view is rendered and its factory returned a view model.")
        return reference.value!
    }

    /// The view model, or `nil` until the factory has returned one.
    public var createdValue: ViewModel? {
        reference.value
    }

    /// A bindable wrapper around the view model for two-way data binding.
    public var projectedValue: Bindable<ViewModel> {
        Bindable(wrappedValue)
    }

    /// Updates the view model state, creating the view model instance if needed.
    ///
    /// This method is called automatically by SwiftUI's DynamicProperty system.
    public nonisolated mutating func update() {
        MainActor.assumeIsolated {
            if reference.value == nil {
                // Set the task-local dependency container for @Injected to work in ViewModels
                reference.value = env.dependenciesContainer.withDependencies {
                    makeViewModel(env)
                }
            }
        }
    }
}
