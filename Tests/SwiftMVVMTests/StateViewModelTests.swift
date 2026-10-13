//
//  StateViewModelTests.swift
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

// MARK: - Test Types for StateViewModel Tests

@Observable
final class ProbeViewModel {
    let origin: String

    init(origin: String) {
        self.origin = origin
    }
}

extension EnvironmentValues {
    @Entry var probeService: String? = nil
}

@MainActor
final class ProbeLog {
    var factoryCalls = 0
    var renderedOrigins: [String] = []
}

struct ClosureFactoryProbe: View {
    let log: ProbeLog
    let isReady: Bool
    let generation: Int

    var body: some View {
        WithViewModel { _ in
            log.factoryCalls += 1
            return isReady ? ProbeViewModel(origin: "call \(log.factoryCalls)") : nil
        } content: { (viewModel: ProbeViewModel) in
            let _ = log.renderedOrigins.append(viewModel.origin)
            Text("\(viewModel.origin) \(generation)")
        }
    }
}

struct KeyPathFactoryProbe: View {
    let log: ProbeLog
    let service: String?

    var body: some View {
        WithViewModel(\.probeService) { service in
            ProbeViewModel(origin: service)
        } content: { viewModel in
            let _ = log.renderedOrigins.append(viewModel.origin)
            Text(viewModel.origin)
        }
        .environment(\.probeService, service)
    }
}

// MARK: - StateViewModel Tests
@Suite("StateViewModel Tests")
@MainActor
struct StateViewModelTests {
    @Test("A factory returning nil renders nothing and is retried until it returns a view model")
    func factoryReturningNilIsRetriedUntilItReturnsAViewModel() throws {
        let log = ProbeLog()
        let renderer = ImageRenderer(content: ClosureFactoryProbe(log: log, isReady: false, generation: 0))
        _ = renderer.cgImage
        #expect(log.factoryCalls > 0)
        #expect(log.renderedOrigins.isEmpty)

        renderer.content = ClosureFactoryProbe(log: log, isReady: true, generation: 1)
        _ = renderer.cgImage
        let createdOrigin = try #require(log.renderedOrigins.last)
        #expect(createdOrigin == "call \(log.factoryCalls)")

        let callsAfterCreation = log.factoryCalls
        renderer.content = ClosureFactoryProbe(log: log, isReady: true, generation: 2)
        _ = renderer.cgImage
        #expect(log.factoryCalls == callsAfterCreation)
        #expect(log.renderedOrigins.last == createdOrigin)
    }

    @Test("A key-path factory waits for the environment value")
    func keyPathFactoryWaitsForTheEnvironmentValue() {
        let log = ProbeLog()
        let renderer = ImageRenderer(content: KeyPathFactoryProbe(log: log, service: nil))
        _ = renderer.cgImage
        #expect(log.renderedOrigins.isEmpty)

        renderer.content = KeyPathFactoryProbe(log: log, service: "late")
        _ = renderer.cgImage
        #expect(log.renderedOrigins.last == "late")

        renderer.content = KeyPathFactoryProbe(log: log, service: "replaced")
        _ = renderer.cgImage
        #expect(log.renderedOrigins.last == "late")
    }
}
