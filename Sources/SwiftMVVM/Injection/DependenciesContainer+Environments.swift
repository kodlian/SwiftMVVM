//
//  DependenciesContainer+Env.swift
//  Template
//
//  Created by Jeremy Marchand on 21/8/25.
//

import SwiftUI

extension EnvironmentValues {
    /// The dependencies container available in the current environment.
    @Entry var dependenciesContainer: DependenciesContainer = .init()
}

extension View {
    /// Configures the dependencies container in the environment.
    ///
    /// - Parameter configure: A closure that receives a mutable reference to the dependencies container
    /// - Returns: A view with the modified dependencies container in its environment
    public func inject(_ configure: @escaping (inout DependenciesContainer) -> Void) -> some View {
        self.transformEnvironment(\.dependenciesContainer) { container in
            configure(&container)
        }
    }

    /// Injects a shared instance into the dependencies container.
    ///
    /// - Parameters:
    ///   - instance: The instance to inject
    ///   - type: The type to register the instance as (defaults to the instance's type)
    ///   - file: The file where injection occurs (for debugging)
    ///   - line: The line where injection occurs (for debugging)
    ///   - function: The function where injection occurs (for debugging)
    /// - Returns: A view with the injected dependency in its environment
    public func inject<T: Sendable>(
        _ instance: T,
        as type: T.Type = T.self,
        file: StaticString = #file,
        line: UInt = #line,
        function: StaticString = #function
    ) -> some View {
        self.inject { c in
            c.register(instance, as: type, file: file, line: line, function: function)
        }
    }

    /// Injects a factory function into the dependencies container.
    ///
    /// - Parameters:
    ///   - type: The type to register the factory for
    ///   - shared: If true, creates a single instance and stores it as shared
    ///   - builder: The factory function that creates instances
    ///   - file: The file where injection occurs (for debugging)
    ///   - line: The line where injection occurs (for debugging)
    ///   - function: The function where injection occurs (for debugging)
    /// - Returns: A view with the injected dependency factory in its environment
    public func inject<T: Sendable>(
        as type: T.Type = T.self,
        shared: Bool = false,
        builder: @Sendable @escaping () -> T,
        file: StaticString = #file,
        line: UInt = #line,
        function: StaticString = #function
    ) -> some View {
        self.inject { c in
            c.register(
                as: type, shared: shared, builder: builder, file: file, line: line,
                function: function)
        }
    }
}

extension EnvironmentValues {
    /// Retrieves a dependency of the specified type from the environment's dependencies container.
    ///
    /// - Parameter type: The type of dependency to retrieve
    /// - Returns: The dependency instance, or nil if not found
    @MainActor public subscript<T>(dependency type: T.Type) -> T? {
        dependenciesContainer[type]
    }
}
