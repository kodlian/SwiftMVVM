# SwiftMVVM

**SwiftMVVM** is a lightweight and pragmatic package for building SwiftUI applications using the **Model–View–ViewModel (MVVM)** architectural pattern.

## Why MVVM and Why This Package?

### The Case for MVVM in SwiftUI

While SwiftUI's reactive nature allows direct model exposure in views, **adding a ViewModel layer becomes beneficial for relatively complex project** where business logic needs to be abstracted away from presentation concerns. This separation makes code more testable, maintainable, and readable.

**Architecture is not one-size-fits-all** – choose MVVM, as well as any architecture, when it adds value to your specific project rather than applying it universally. For simple project, direct model binding might be sufficient.

### Observable Limitations

SwiftUI's `@Observable` macro is powerful and should be preferred over the older `ObservableObject` for better:

- View dependency tracking
- Passthrough observation from observable model
- Performance optimization

However, `@Observable` and `@State` have limitations when working with complex view model instantiation patterns and dependency injection. **This package addresses these gaps** while preserving all the benefits of `@Observable`.

## Features

- 🔗 **ViewModelState**: Property wrapper for managing observable ViewModels with lifecycle-aware instantiation
- 🤲 **WithViewModel**: Inline ViewModel creation with dependency injection support
- 💉 **Deep Injection**: Simple service injection deep into view hierarchies for ViewModels
- 🎯 **@Inject**: Property wrapper for seamless dependency injection in ViewModels
- 🧵 **Concurrency Safe**: Full support for Swift 6 strict concurrency
- 📱 **Modern SwiftUI**: Built for iOS 17+, macOS 14+, and other Apple modern platforms
- 🪶 **Minimal Impact**: Preserves SwiftUI's composition and navigation patterns without architectural constraints

## Design Philosophy

SwiftMVVM is designed to **add the minimal possible layer** to SwiftUI while enabling boilerplate free ViewModel architecture. Key principles:

**Preserve SwiftUI's nature**: Use all SwiftUI composition, navigation, and state management features without rethinking your architecture or fighting SwiftUI APIs.

**Flexible composition**: Fully compose your views as SwiftUI intends – Views can contain ViewModels, or pure View components, or mix both as needed.

**Simple service injection**: Get services to ViewModels without complex dependency injection frameworks or factories.

**Optional adoption**: Choose to use the built-in injection system or not, or use only specific ViewModel features that add value to your project.

**Observable-first**: Built around Swift's modern `@Observable` macro for optimal performance and SwiftUI integration.

## Installation

### Swift Package Manager

Add SwiftMVVM to your project via Xcode:

1. Go to **File** → **Add Package Dependencies**
2. Enter: `https://github.com/kodlian/SwiftMVVM`
3. Select your desired version

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/kodlian/SwiftMVVM", from: "1.0.0")
]
```

## Quick Start

### Basic ViewModel Usage

```swift
import SwiftMVVM

@Observable
class CounterViewModel {
    var count = 0

    func increment() {
        count += 1
    }
}

struct ContentView: View {
    @ViewModelState var viewModel = CounterViewModel()

    var body: some View {
        VStack {
            Text("Count: \(viewModel.count)")
            Button("Increment", action: viewModel.increment)
        }
    }
}
```

### Passing Parameters to ViewModel

When your ViewModel needs initialization parameters, use the closure-based initializer:

```swift
@Observable
class ProductDetailViewModel {
    let productId: String

    init(productId: String) {
        self.productId = productId
    }
}

struct ProductDetailView: View {
    @ViewModelState var viewModel: ProductDetailViewModel

    init(productId: String) {
        self._viewModel = ViewModelState { _ in
            ProductDetailViewModel(productId: productId)
        }
    }

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else if let product = viewModel.product {
                Text(product.name)
                Text(product.description)
            }
        }
    }
}
```

### With Dependency Injection

```swift
protocol UserService {
    func fetchUsers() async -> [User]
}

@Observable
class UserViewModel {
    private let userService: UserService
    @State var users: [User] = []

    init(userService: UserService) {
        self.userService = userService
    }

    func loadUsers() async {
        users = await userService.fetchUsers()
    }
}

struct UserListView: View {
    @ViewModelState var viewModel: UserViewModel

    init() {
        self._viewModel = ViewModelState { env in
            UserViewModel(userService: env[dependency: UserService.self]!)
        }
    }

    var body: some View {
        List(viewModel.users) { user in
            Text(user.name)
        }
        .task { await viewModel.loadUsers() }
    }
}

struct ParentView: View {
    var body: some View {
        NavigationView {
            UserListView()
        }
        .inject(MockUserService()) // Inject at parent level
    }
}
```

### Or Use @Inject for Less Boilerplate

```swift
@Observable
class UserViewModel {
    @ObservationIgnored @Inject var userService: UserService
    @State var users: [User] = []

    func loadUsers() async {
        users = await userService.fetchUsers()
    }
}

struct UserListView: View {
    @ViewModelState var viewModel = UserViewModel()

    var body: some View {
        List(viewModel.users) { user in
            Text(user.name)
        }
        .task { await viewModel.loadUsers() }
    }
}

struct ParentView: View {
    var body: some View {
        NavigationView {
            UserListView()
        }
        .inject(MockUserService()) // Still inject at parent level
    }
}
```

## Core Components

### ViewModelState

A property wrapper that manages Observable ViewModels with proper lifecycle:

```swift
struct MyView: View {
    @ViewModelState var viewModel: MyViewModel

    init() {
        self._viewModel = ViewModelState { env in
            MyViewModel(
                service: env[dependency: MyService.self]!
            )
        }
    }
}
```

### WithViewModel

For inline ViewModel creation:

```swift
struct MyView: View {
    var body: some View {
        WithViewModel { _ in
            MyViewModel()
        } content: { viewModel in
            VStack {
                Text(viewModel.title)
                Button("Action", action: viewModel.performAction)
            }
        }
    }
}
```

### Dependency Injection

Type-safe dependency container with SwiftUI integration:

```swift
// Register dependencies at parent level
ContentView()
    .inject(DatabaseService())
    .inject(as: NetworkService.self) { NetworkService(baseURL: "https://api.example.com") }

// Access in child ViewModels anywhere in the hierarchy
@Observable
class MyViewModel {
    @ObservationIgnored @Inject var database: DatabaseService
    @ObservationIgnored @Inject var network: NetworkService
}
```

**Important**: This injection system is designed for **providing services to ViewModels deep in view hierarchies**, not for building complex dependency graphs between services. It's optimized for minimal SwiftUI impact while enabling boilerplate free MVVM architecture.

### Safety Considerations and Best Practices

Environment-based injection trades compile-time safety for significantly reduced boilerplate and architectural simplicity in SwiftUI applications. This is a deliberate design choice to keep your SwiftUI code clean and maintainable.

**Best Practice**: Inject dependencies at **key architectural boundaries** in your app:

- Root of the application (`App` or main `ContentView`)
- Root of authenticated user flows
- Beginning of major feature flows (editing, onboarding, etc.)
- Modal presentations or navigation destinations

**Debugging Dependencies**: You can easily inspect what dependencies are available at any point by printing the container's debug description in your ViewModel initializer:

```swift
@Observable
class MyViewModel {
    @ObservationIgnored @Inject var userService: UserService

    init() {
        // Debug: Print available dependencies and their injection points
        debugPrint(DependenciesContainer.current)
    }
}
```

Or when using the closure-based approach with `ViewModelState` or `WithViewModel`:

```swift
struct MyView: View {
    @ViewModelState var viewModel: MyViewModel

    init() {
        self._viewModel = ViewModelState { env in
            // Debug: Print available dependencies from environment
            let container = env.dependenciesContainer
            debugPrint(container)

            return MyViewModel(service: env[dependency: MyService.self]!)
        }
    }
}
```

This will show you exactly where each dependency was injected in the view hierarchy, making debugging straightforward.

### KeyPath Injection

Access nested properties from composite dependencies:

```swift
struct AppServices {
    let database: DatabaseService
    let cache: CacheService
}

// Inject the composite service at parent level
ContentView()
    .inject(AppServices(database: db, cache: cache))

@Observable
class MyViewModel {
    @ObservationIgnored @Inject(\.database) var database: DatabaseService
    @ObservationIgnored @Inject(\.cache) var cache: CacheService
}
```

## Future Directions

### Macro-Based Improvements

I am exploring Swift Macros to further reduce boilerplate and improve the developer experience:

- **Automatic `@ObservationIgnored`**: Eliminate the need to manually add `@ObservationIgnored` before `@Inject` properties
- **Initializer Injection**: Enable dependency injection directly within ViewModel initializers without requiring property wrappers

These improvements would allow for cleaner ViewModel definitions like:

```swift
@ViewModel // Future macro that adds @Observable and automatically adds @ObservationIgnored to all @Inject properties
class UserViewModel {
    @Inject var userService: UserService  // No @ObservationIgnored needed

    init(networkService: NetworkService = #inject(NetworkService)) {  // Future: inject in init macro
        // Initialization with injected dependencies
        ...
    }
}
```

## Requirements

- iOS 17.0+ / macOS 14.0+ / tvOS 17.0+ / watchOS 10.0+
- Swift 6.1+
- Xcode 16.0+

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

SwiftMVVM is available under the MIT license. See the LICENSE file for more info.

## Author

Created by [Jérémy Marchand](https://github.com/kodlian)
