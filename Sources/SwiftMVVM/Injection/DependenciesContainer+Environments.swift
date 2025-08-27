//
//  DependenciesContainer+Environments.swift
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
