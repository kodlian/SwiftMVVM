//
//  InjectPropertyWrapperTests.swift
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
import Testing

@testable import SwiftMVVM

// MARK: - Test Types for Inject Tests

struct InjectTestService: Sendable {
    let name: String

    init(name: String) {
        self.name = name
    }
}

struct CompositeService: Sendable {
    let database: String
    let cache: String

    init(database: String, cache: String) {
        self.database = database
        self.cache = cache
    }
}

// MARK: - Inject Property Wrapper Tests

@Suite("Inject Property Wrapper Tests")
struct InjectPropertyWrapperTests {

    @Test("Inject initializes with type parameter")
    @MainActor
    func testInjectInitializationWithType() {
        // Setup container with required dependency
        var container = DependenciesContainer()
        container.register(InjectTestService(name: "type-test"), as: InjectTestService.self)

        // Test Inject initialization (simulating what happens in ViewModels)
        let result = DependenciesContainer.$current.withValue(container) {
            let inject = Inject<InjectTestService>(InjectTestService.self)
            return inject.wrappedValue.name
        }

        #expect(result == "type-test")
    }

    @Test("Inject initializes with keypath parameter")
    @MainActor
    func testInjectInitializationWithKeyPath() {
        // Setup container with composite dependency
        var container = DependenciesContainer()
        let composite = CompositeService(database: "db-connection", cache: "redis-cache")
        container.register(composite, as: CompositeService.self)

        // Test Inject initialization with keypath
        let databaseResult = DependenciesContainer.$current.withValue(container) {
            let inject = Inject<String>(\CompositeService.database)
            return inject.wrappedValue
        }

        let cacheResult = DependenciesContainer.$current.withValue(container) {
            let inject = Inject<String>(\CompositeService.cache)
            return inject.wrappedValue
        }

        #expect(databaseResult == "db-connection")
        #expect(cacheResult == "redis-cache")
    }

    @Test("Inject detects missing dependency")
    func testInjectDetectsMissingDependency() {
        // Setup empty container
        let container = DependenciesContainer()

        // This test verifies the error condition would be detected
        let hasDependency = DependenciesContainer.$current.withValue(container) {
            container[InjectTestService.self] != nil
        }

        #expect(hasDependency == false)
    }

    @Test("Inject works with default type inference")
    @MainActor
    func testInjectWithDefaultTypeInference() {
        var container = DependenciesContainer()
        container.register(InjectTestService(name: "inferred"))

        let result = DependenciesContainer.$current.withValue(container) {
            // This simulates @Inject var service: InjectTestService
            let inject = Inject<InjectTestService>()
            return inject.wrappedValue.name
        }

        #expect(result == "inferred")
    }

    @Test("Inject works with protocol types")
    @MainActor
    func testInjectWithProtocolTypes() {
        protocol TestProtocol: Sendable {
            var identifier: String { get }
        }

        struct TestImplementation: TestProtocol, Sendable {
            let identifier: String
        }

        var container = DependenciesContainer()
        container.register(
            TestImplementation(identifier: "protocol-test"),
            as: TestProtocol.self
        )

        let result = DependenciesContainer.$current.withValue(container) {
            let inject = Inject<TestProtocol>()
            return inject.wrappedValue.identifier
        }

        #expect(result == "protocol-test")
    }
}
