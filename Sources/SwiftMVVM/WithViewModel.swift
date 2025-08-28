//
//  WithViewModel.swift
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

/// Supplies an observable view model to a view's hierarchy with dependency injection.
///
/// The purpose of `WithViewModel` is to make it possible to instantiate
/// observable view models from environment values, while keeping the object
/// alive as long as the view is rendered. This is useful when you need to create
/// a view model inline with access to services from individual dependencies outside the view it will be attached.
///
/// For example with manual dependency injection:
///
/// ```swift
/// struct MyView: View {
///     var body: some View {
///         WithViewModel { env in
///             MyViewModel(
///                 database: env[dependency: DatabaseService.self]!,
///                 network: env[dependency: NetworkService.self]!
///             )
///         } content: { viewModel in
///             ContentView(viewModel: viewModel)
///         }
///     }
/// }
/// ```
///
/// Or with @Injected (recommended):
///
/// ```swift
/// @Observable class MyViewModel {
///     @ObservationIgnored @Injected var service: MyService
/// }
///
/// struct MyView: View {
///     var body: some View {
///         WithViewModel { _ in
///             MyViewModel()
///         } content: { viewModel in
///             ContentView(viewModel: viewModel)
///         }
///     }
/// }
/// ```
///
/// `WithViewModel` makes sure a single instance of the observable
/// is created for the whole lifetime of the view. It is thus possible to
/// perform work from the object initializer.
public struct WithViewModel<ViewModel: AnyObject & Observable, Content: View>: View {
    @ViewModelState<ViewModel> var viewModel: ViewModel
    private let content: (ViewModel) -> Content

    /// Creates a WithViewModel with a factory closure and content builder.
    ///
    /// - Parameters:
    ///   - makeViewModel: A closure that creates the view model using environment values
    ///   - content: A view builder that receives the view model and returns the content view
    public init(
        _ makeViewModel: @escaping (EnvironmentValues) -> ViewModel,
        @ViewBuilder content: @escaping (ViewModel) -> Content
    ) {
        self._viewModel = ViewModelState(makeViewModel: makeViewModel)
        self.content = content
    }

    /// The body of the view that renders the content with the view model.
    public var body: some View {
        content(viewModel)
    }
}
