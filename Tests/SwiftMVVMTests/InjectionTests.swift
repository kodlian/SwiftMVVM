//
//  InjectionTests.swift
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

import Testing

@testable import SwiftMVVM

@Suite("Injection Value Tests")
struct InjectionValueTests {

    @Test("Shared value resolves correctly")
    func testSharedValueResolve() {
        let service = MockService(name: "SharedTest")
        let injection = DependenciesContainer.Injection(
            value: .shared(service),
            debugInfo: .init(
                file: #file,
                line: #line,
                function: #function,
                type: MockService.self
            )
        )

        let resolved: MockService? = injection.resolve()
        #expect(resolved?.name == "SharedTest")
    }

    @Test("Builder value resolves correctly")
    func testBuilderValueResolve() {
        let injection = DependenciesContainer.Injection(
            value: .builder { MockService(name: "BuilderTest") },
            debugInfo: .init(
                file: #file,
                line: #line,
                function: #function,
                type: MockService.self
            )
        )

        let resolved: MockService? = injection.resolve()
        #expect(resolved?.name == "BuilderTest")
    }

    @Test("Resolve returns nil for wrong type")
    func testResolveReturnsNilForWrongType() {
        let service = MockService()
        let injection = DependenciesContainer.Injection(
            value: .shared(service),
            debugInfo: .init(
                file: #file,
                line: #line,
                function: #function,
                type: MockService.self
            )
        )

        let resolved: String? = injection.resolve()
        #expect(resolved == nil)
    }
}
