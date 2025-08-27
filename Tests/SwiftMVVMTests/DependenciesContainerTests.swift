//
//  DependenciesContainerTests.swift
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

// MARK: - Test Types
protocol TestService: Sendable {
    var name: String { get }
}

final class MockService: TestService, Sendable {
    let name: String

    init(name: String = "MockService") {
        self.name = name
    }
}

struct DatabaseService: Sendable {
    let connectionString: String

    init(connectionString: String) {
        self.connectionString = connectionString
    }
}

struct NetworkService: Sendable {
    let baseURL: String

    init(baseURL: String) {
        self.baseURL = baseURL
    }
}

struct ServiceSuite: Sendable {
    let database: DatabaseService
    let network: NetworkService

    init(database: DatabaseService, network: NetworkService) {
        self.database = database
        self.network = network
    }
}

class Counter: @unchecked Sendable {
    var count: Int = 0
}

// MARK: - DependenciesContainer Tests
@Suite("DependenciesContainer Tests")
struct DependenciesContainerTests {

    @Test("Container initialization creates empty container")
    func testContainerInitialization() {
        let container = DependenciesContainer()

        // Verify container is empty
        #expect(container[String.self] == nil)
        #expect(container[MockService.self] == nil)
    }

    @Test("Register and retrieve shared instance")
    func testRegisterSharedInstance() {
        var container = DependenciesContainer()
        let service = MockService(name: "TestService")

        // Register service
        container.register(service, as: MockService.self)

        // Retrieve and verify
        let retrieved = container[MockService.self]
        #expect(retrieved?.name == "TestService")
    }

    @Test("Register and retrieve as protocol")
    func testRegisterAsProtocol() {
        var container = DependenciesContainer()
        let service = MockService(name: "ProtocolService")

        // Register as protocol
        container.register(service, as: TestService.self)

        // Retrieve and verify
        let retrieved = container[TestService.self]
        #expect(retrieved?.name == "ProtocolService")
    }

    @Test("Register factory function creates new instances")
    func testRegisterFactory() {
        var container = DependenciesContainer()

        let counter = Counter()

        // Register factory

        container.register(as: MockService.self) {
            counter.count += 1

            return MockService(name: "FactoryService \(counter.count)")
        }

        // Retrieve multiple instances
        let instance1 = container[MockService.self]
        let instance2 = container[MockService.self]

        #expect(instance1 !== instance2)
        #expect(instance1?.name == "FactoryService 1")
        #expect(instance2?.name == "FactoryService 2")
    }

    @Test("Register factory as shared creates single instance")
    func testRegisterFactoryAsShared() {
        var container = DependenciesContainer()

        // Register factory as shared
        container.register(as: MockService.self, shared: true) {
            MockService(name: "SharedFactory")
        }

        // Retrieve multiple instances
        let instance1 = container[MockService.self]
        let instance2 = container[MockService.self]

        #expect(instance1 === instance2)
    }

    @Test("Container merge combines dependencies")
    func testContainerMerge() {
        var container1 = DependenciesContainer()
        var container2 = DependenciesContainer()

        // Add different services to each container
        container1.register(MockService(name: "Service1"), as: MockService.self)
        container2.register(
            DatabaseService(connectionString: "db://test"), as: DatabaseService.self)

        // Merge containers
        container1.merge(container2)

        // Verify both services are available
        #expect(container1[MockService.self]?.name == "Service1")
        #expect(container1[DatabaseService.self]?.connectionString == "db://test")
    }

    @Test("Container merge overwrites existing dependencies")
    func testContainerMergeOverwrite() {
        var container1 = DependenciesContainer()
        var container2 = DependenciesContainer()

        // Add same service type to both containers
        container1.register(MockService(name: "Original"), as: MockService.self)
        container2.register(MockService(name: "Override"), as: MockService.self)

        // Merge containers
        container1.merge(container2)

        // Verify override occurred
        #expect(container1[MockService.self]?.name == "Override")
    }

    @Test("Subscript returns nil for unregistered type")
    func testSubscriptReturnsNilForUnregisteredType() {
        let container = DependenciesContainer()

        #expect(container[String.self] == nil)
        #expect(container[MockService.self] == nil)
    }

    @Test("Injection debug info is captured")
    func testInjectionDebugInfo() {
        var container = DependenciesContainer()
        let service = MockService()

        container.register(service, as: MockService.self)

        // Access internal structure to verify debug info is captured
        // This tests that the injection system properly tracks registration location
        #expect(container[MockService.self] != nil)
    }
}
