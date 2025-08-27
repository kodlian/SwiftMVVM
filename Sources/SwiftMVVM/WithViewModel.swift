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
/// Or with @Inject (recommended):
///
/// ```swift
/// @Observable class MyViewModel {
///     @ObservationIgnored @Inject var service: MyService
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
