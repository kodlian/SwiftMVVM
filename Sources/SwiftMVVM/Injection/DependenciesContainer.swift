//
//  DependenciesContainer.swift
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

/// A container for managing dependency injection in SwiftUI applications.
///
/// `DependenciesContainer` provides a type-safe way to register and resolve dependencies
/// throughout your application. It supports both shared instances and factory-based
/// dependency creation with automatic debugging information tracking.
///
/// Example usage:
/// ```swift
/// var container = DependenciesContainer()
/// container.register(MyService(), as: MyService.self)
/// container.register(as: NetworkService.self) { NetworkService() }
///
/// let service: MyService? = container[MyService.self]
/// ```
public struct DependenciesContainer: Sendable {
    /// Task-local storage for the current dependencies container.
    /// Used by `@Inject` property wrapper to access dependencies within ViewModels.
    @TaskLocal static var current: DependenciesContainer?

    /// Represents a single dependency injection with its value and debug information.
    public struct Injection: Sendable, CustomDebugStringConvertible {
        /// Debug information about where the dependency was registered.
        public struct DebugInfo: CustomDebugStringConvertible, Sendable {
            public let file: StaticString
            public let line: UInt
            public let function: StaticString
            public let type: Any.Type

            public var debugDescription: String {
                "\(type) from \(file):\(line) - \(function)"
            }
        }

        /// The storage strategy for the injected dependency.
        public enum Value: Sendable {
            /// A shared instance that was registered directly.
            case shared(Sendable)
            /// A factory function that creates new instances on demand.
            case builder(@Sendable () -> Any)

            var debugPrefix: String {
                switch self {
                case .shared:
                    return "Shared"
                case .builder:
                    return "Builder"
                }
            }
        }

        public let value: Value
        public let debugInfo: DebugInfo

        public var debugDescription: String {
            "\(value.debugPrefix) - \(debugInfo.debugDescription)"
        }

        /// Resolves the dependency to the requested type.
        /// - Returns: The dependency instance cast to the requested type, or nil if not compatible.
        public func resolve<T>() -> T? {
            switch value {
            case .shared(let value):
                return value as? T
            case .builder(let builder):
                return builder() as? T
            }
        }
    }

    private(set) var services: [ObjectIdentifier: Injection] = [:]

    /// Creates a new empty dependencies container.
    public init() {}

    /// Registers a shared instance of a dependency.
    ///
    /// - Parameters:
    ///   - value: The instance to register
    ///   - type: The type to register the instance as (defaults to the value's type)
    public mutating func register<T: Sendable>(
        _ value: T,
        as type: T.Type = T.self,
        file: StaticString = #file,
        line: UInt = #line,
        function: StaticString = #function
    ) {
        services[ObjectIdentifier(type)] = Injection(
            value: .shared(value),
            debugInfo: .init(file: file, line: line, function: function, type: type)
        )
    }

    /// Registers a factory function for creating dependencies.
    ///
    /// - Parameters:
    ///   - type: The type to register the factory for
    ///   - shared: If true, creates a single instance and stores it as shared
    ///   - builder: The factory function that creates instances
    public mutating func register<T: Sendable>(
        as type: T.Type = T.self,
        shared: Bool = false,
        builder: @Sendable @escaping () -> T,
        file: StaticString = #file,
        line: UInt = #line,
        function: StaticString = #function
    ) {
        if shared {
            register(builder(), as: type, file: file, line: line, function: function)
        } else {
            services[ObjectIdentifier(type)] = Injection(
                value: .builder(builder),
                debugInfo: .init(file: file, line: line, function: function, type: type)
            )
        }
    }

    /// Retrieves a dependency of the specified type.
    ///
    /// - Parameter type: The type of dependency to retrieve
    /// - Returns: The dependency instance, or nil if not found
    public subscript<T>(_ type: T.Type) -> T? {
        services[ObjectIdentifier(type)]?.resolve()
    }

    /// Merges another dependencies container into this one.
    ///
    /// - Parameter other: The container to merge from
    public mutating func merge(_ other: DependenciesContainer) {
        for (k, v) in other.services {
            services[k] = v
        }
    }
}
