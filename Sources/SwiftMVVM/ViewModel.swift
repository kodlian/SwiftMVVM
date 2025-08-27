import SwiftUI

/// A property wrapper type that instantiates an observable view model with dependency injection.
///
/// It's like `@State` for view models, except that just like `@StateObject` its
/// initializer accepts a closure so that a single instance of the
/// observable view model is created for the whole lifetime of the view.
/// Additionally, it provides safe dependency injection by passing the full
/// `EnvironmentValues` to the view model factory closure.
///
/// For example with dependency injection from environment:
///
/// ```swift
/// struct MyView: View {
///     @ViewModelState var viewModel: MyViewModel
///
///     init() {
///         self._viewModel = ViewModelState { env in
///             MyViewModel(
///                 database: env[dependency: DatabaseService.self]!,
///                 network: env[dependency: NetworkService.self]!
///             )
///         }
///     }
/// }
/// ```
///
/// Or use @Inject directly in the ViewModel for less boilerplate:
///
/// ```swift
/// @Observable
/// class MyViewModel {
///    @ObservationIgnored @Inject<NetworkService> var networkService: NetworkService
///    @ObservationIgnored @Inject(\ServiceSuite.service1) var service1: NetworkService
/// }
///
/// struct MyView: View {
///     @ViewModelState var viewModel = MyViewModel()
/// }
/// ```
@propertyWrapper @MainActor
public struct ViewModelState<ViewModel: AnyObject & Observable>: DynamicProperty {
    class LazyRerefence {
        var value: ViewModel?
    }

    @State private var reference = LazyRerefence()
    @Environment(\.self) private var env
    let makeViewModel: (EnvironmentValues) -> ViewModel

    /// Creates a ViewModelState with a factory closure that receives environment values.
    ///
    /// - Parameter makeViewModel: A closure that creates the view model using environment values
    public init(makeViewModel: @escaping (EnvironmentValues) -> ViewModel) {
        self.makeViewModel = makeViewModel
    }

    /// Creates a ViewModelState with a simple autoclosure that creates the view model.
    ///
    /// This initializer is convenient when the view model doesn't need environment values.
    ///
    /// - Parameter wrappedValue: An autoclosure that creates the view model
    public init(wrappedValue: @autoclosure @escaping () -> ViewModel) {
        self.makeViewModel = { _ in
            wrappedValue()
        }
    }

    /// The view model instance.
    ///
    /// Accessing this property before the view is rendered will cause a runtime error.
    public var wrappedValue: ViewModel {
        precondition(
            reference.value != nil,
            "ViewModelState should be accessed only after the view is rendered.")
        return reference.value!
    }

    /// A bindable wrapper around the view model for two-way data binding.
    public var projectedValue: Bindable<ViewModel> {
        Bindable(wrappedValue)
    }

    /// Updates the view model state, creating the view model instance if needed.
    ///
    /// This method is called automatically by SwiftUI's DynamicProperty system.
    public nonisolated mutating func update() {
        MainActor.assumeIsolated {
            if reference.value == nil {
                // Use the dependency container from the environment
                // Dependencies are automatically populated when .inject() is called
                let container = env.dependenciesContainer

                // Set the task-local dependency container for @Inject to work in ViewModels
                reference.value = DependenciesContainer.$current.withValue(container) {
                    makeViewModel(env)
                }
            }
        }
    }
}
