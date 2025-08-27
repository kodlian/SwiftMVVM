//
//  DependenciesEnvironmentTests.swift
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

// MARK: - Test Types for Environment Tests

struct EnvironmentTestService: Sendable {
    let identifier: String

    init(identifier: String) {
        self.identifier = identifier
    }
}

struct ConfigService: Sendable {
    let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }
}

// MARK: - Environment Integration Tests
@Suite("Dependencies Environment Tests")
struct DependenciesEnvironmentTests {
    @Test("Environment subscript retrieves dependencies")
    @MainActor
    func testEnvironmentSubscript() {
        var environmentValues = EnvironmentValues()

        // Add service to container
        var container = environmentValues.dependenciesContainer
        container.register(EnvironmentTestService(identifier: "subscript-test"))
        environmentValues.dependenciesContainer = container

        // Test subscript access
        let service = environmentValues[dependency: EnvironmentTestService.self]
        #expect(service?.identifier == "subscript-test")

        // Test nil for unregistered type
        let unregistered = environmentValues[dependency: ConfigService.self]
        #expect(unregistered == nil)
    }
}
