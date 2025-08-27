import SwiftUI

// MARK: - @Inject Property Wrapper for ViewModels

/// A property wrapper that injects dependencies into ViewModels from the environment.
/// Unlike `@Environment`, this can be used directly in Observable ViewModels.
/// The dependency is resolved immediately during ViewModel initialization.
///
/// Usage:
/// ```swift
/// @Observable
/// class MyViewModel {
///     @Inject var database: DatabaseService
///     @Inject var container: AppServicesContainer
/// }
/// ```
@propertyWrapper @MainActor
public struct Inject<T> {
    private let value: T

    /// Creates an Inject property wrapper for the specified type.
    ///
    /// The dependency must be registered in the environment using `.inject(_:)` modifier.
    ///
    /// - Parameter type: The type of dependency to inject (defaults to T.self)
    public init(_ type: T.Type = T.self) {
        guard let container = DependenciesContainer.current else {
            fatalError(
                "@Inject can only be used within ViewModels created through ViewModelState or WithViewModel"
            )
        }
        guard let value = container[type] else {
            fatalError(
                "No \(T.self) found in the dependency container. Inject it with .inject(_:) at a parent view."
            )
        }
        self.value = value
    }

    /// Creates an Inject property wrapper using a key path to access a dependency.
    ///
    /// This allows injecting properties from a larger dependency object.
    ///
    /// - Parameter keyPath: A key path from the dependency type D to the desired property T
    public init<D>(_ keyPath: KeyPath<D, T>) {
        guard let container = DependenciesContainer.current else {
            fatalError(
                "@Inject can only be used within ViewModels created through ViewModelState or WithViewModel"
            )
        }
        guard let value = container[D.self]?[keyPath: keyPath] else {
            fatalError(
                "No dependency for keyPath \(keyPath) found in the dependency container. Inject the base type with .inject(_:) at a parent view."
            )
        }
        self.value = value
    }

    /// The injected dependency value.
    public var wrappedValue: T {
        return value
    }
}
