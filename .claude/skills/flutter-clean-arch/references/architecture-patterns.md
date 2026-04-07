# PeerAssess Architecture Patterns Reference

This document contains the exact code patterns used in the PeerAssess codebase. When generating or reviewing code, match these patterns precisely.

## Table of Contents
1. [Project Structure](#project-structure)
2. [Domain Layer — Model](#domain-layer--model)
3. [Domain Layer — Abstract Repository](#domain-layer--abstract-repository)
4. [Data Layer — Abstract Data Source](#data-layer--abstract-data-source)
5. [Data Layer — Local Data Source](#data-layer--local-data-source)
6. [Data Layer — Remote Data Source](#data-layer--remote-data-source)
7. [Data Layer — Concrete Repository](#data-layer--concrete-repository)
8. [UI Layer — Controller](#ui-layer--controller)
9. [UI Layer — Views (General Conventions)](#ui-layer--views-general-conventions)
10. [DI Registration in main.dart](#di-registration-in-maindart)
11. [Naming Conventions](#naming-conventions)
12. [Import Conventions](#import-conventions)

---

## Project Structure

```
lib/features/[feature_name]/
├── domain/
│   ├── models/
│   │   └── [entity].dart
│   └── repositories/
│       └── i_[entity]_repository.dart
├── data/
│   ├── datasources/
│   │   ├── i_[entity]_source.dart        ← Abstract interface at root
│   │   ├── remote/
│   │   │   └── remote_[entity]_source.dart
│   │   └── local/
│   │       └── local_[entity]_source.dart
│   └── repositories/
│       └── [entity]_repository.dart
└── ui/
    ├── viewmodels/
    │   └── [entity]_controller.dart
    └── views/
        └── [view_name]_page.dart          ← One file per view/screen
```

---

## Domain Layer — Model

Location: `domain/models/[entity].dart`

The domain model is a plain Dart class with no framework dependencies. It has:
- A constructor with named parameters (optional `id`, required fields)
- A `fromJson` factory constructor
- A `toJson` method
- A `toJsonNoId` method (for creation requests without an ID)
- A `toString` override for debugging

```dart
class Product {
  Product({
    this.id,
    required this.name,
    required this.description,
    required this.quantity,
  });

  String? id;
  String name;
  String description;
  int quantity;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json["_id"],
        name: json["name"] ?? "---",
        description: json["description"] ?? "---",
        quantity: json["quantity"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "_id": id ?? "0",
        "name": name,
        "description": description,
        "quantity": quantity,
      };

  Map<String, dynamic> toJsonNoId() => {
        "name": name,
        "description": description,
        "quantity": quantity,
      };

  @override
  String toString() {
    return '[Entity]{entry_id: $id, name: $name, ...}';
  }
}
```

**Key points:**
- `id` is always `String?` (nullable) — assigned by the backend or generated locally
- `fromJson` uses null-safe defaults (`?? "---"`, `?? 0`)
- Fields are mutable (not `final`) — this allows in-place updates in views

---

## Domain Layer — Abstract Repository

Location: `domain/repositories/i_[entity]_repository.dart`

Defines the contract that the data layer must implement. The domain layer only knows about this interface — never the concrete implementation.

```dart
import '../models/product.dart';

abstract class IProductRepository {
  Future<List<Product>> getProducts();

  Future<bool> addProduct(Product p);

  Future<bool> updateProduct(Product p);

  Future<bool> deleteProduct(Product p);

  Future<bool> deleteProducts();
}
```

**Key points:**
- Uses `abstract class` (not `abstract interface` from Dart 3)
- Prefix with `I` to distinguish from concrete implementations
- Returns `Future<bool>` for write operations, `Future<List<T>>` for reads
- Import only from within the domain layer

---

## Data Layer — Abstract Data Source

Location: `data/datasources/i_[entity]_source.dart`

Lives at the root of the `datasources/` folder. Both local and remote sources implement this interface.

```dart
import '../../domain/models/product.dart';

abstract class IProductSource {
  Future<List<Product>> getProducts();

  Future<bool> addProduct(Product product);

  Future<bool> updateProduct(Product product);

  Future<bool> deleteProduct(Product product);

  Future<bool> deleteProducts();
}
```

**Key points:**
- Mirrors the repository interface (same method signatures)
- The abstract interface sits at `datasources/` root, shared by both local and remote
- Uses relative imports to reach the domain model

---

## Data Layer — Local Data Source

Location: `data/datasources/local/local_[entity]_source.dart`

In-memory implementation for development/testing. Uses a private `List<T>` as storage.

```dart
import '../../../domain/models/product.dart';
import '../i_remote_product_source.dart';

class LocalProductSource implements IProductSource {
  final List<Product> _products = <Product>[];

  LocalProductSource();

  @override
  Future<bool> addProduct(Product product) {
    product.id = DateTime.now().millisecondsSinceEpoch.toString();
    _products.add(product);
    return Future.value(true);
  }

  @override
  Future<bool> deleteProduct(Product product) {
    _products.remove(product);
    return Future.value(true);
  }

  @override
  Future<bool> deleteProducts() {
    _products.clear();
    return Future.value(true);
  }

  @override
  Future<List<Product>> getProducts() {
    return Future.value(_products);
  }

  @override
  Future<bool> updateProduct(Product product) {
    var index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      return Future.value(true);
    }
    return Future.value(false);
  }
}
```

**Key points:**
- No constructor dependencies — works standalone
- Generates IDs with `DateTime.now().millisecondsSinceEpoch.toString()`
- Returns `Future.value()` (not `async`) since everything is synchronous
- Update uses `indexWhere` to find by ID, returns `false` if not found

---

## Data Layer — Remote Data Source

Location: `data/datasources/remote/remote_[entity]_source.dart`

HTTP-based implementation. Takes an `http.Client` via constructor injection.

```dart
import 'package:loggy/loggy.dart';
import '../../../domain/models/product.dart';
import 'package:http/http.dart' as http;

import '../i_remote_product_source.dart';

class RemoteProductSource implements IProductSource {
  final http.Client httpClient;

  RemoteProductSource(this.httpClient);

  @override
  Future<List<Product>> getProducts() async {
    List<Product> products = [];
    // TODO: Implement API call
    return Future.value(products);
  }

  @override
  Future<bool> addProduct(Product product) async {
    logInfo("Web service, Adding product $product");
    return Future.value(true);
  }

  @override
  Future<bool> updateProduct(Product product) async {
    logInfo("Web service, Updating product with id $product");
    return Future.value(true);
  }

  @override
  Future<bool> deleteProduct(Product product) async {
    logInfo("Web service, Deleting product with id $product");
    return Future.value(true);
  }

  @override
  Future<bool> deleteProducts() async {
    List<Product> products = await getProducts();
    for (var product in products) {
      await deleteProduct(product);
    }
    return Future.value(true);
  }
}
```

**Key points:**
- Constructor receives `http.Client` for testability
- Uses `loggy` for logging all operations
- Methods are `async` even if currently stubbed
- `deleteProducts` iterates and delegates to `deleteProduct`

---

## Data Layer — Concrete Repository

Location: `data/repositories/[entity]_repository.dart`

Delegates all calls to the data source. This is the "glue" between domain and data layers.

```dart
import '../../domain/repositories/i_product_repository.dart';
import '../datasources/i_remote_product_source.dart';
import '../../domain/models/product.dart';

class ProductRepository implements IProductRepository {
  late IProductSource userSource;

  ProductRepository(this.userSource);

  @override
  Future<List<Product>> getProducts() async => await userSource.getProducts();

  @override
  Future<bool> addProduct(Product user) async =>
      await userSource.addProduct(user);

  @override
  Future<bool> updateProduct(Product user) async =>
      await userSource.updateProduct(user);

  @override
  Future<bool> deleteProduct(Product user) async =>
      await userSource.deleteProduct(user);

  @override
  Future<bool> deleteProducts() async => await userSource.deleteProducts();
}
```

**Key points:**
- `implements` the domain's `IProductRepository`
- Constructor receives `IProductSource` (the abstraction, not a concrete class)
- Uses `late` keyword for the source field
- Each method is a one-liner that delegates to the source
- Uses `async => await` pattern for delegation

---

## UI Layer — Controller

Location: `ui/viewmodels/[entity]_controller.dart`

GetX controller that manages state and delegates to the repository.

```dart
import 'package:f_clean_template/features/product/domain/repositories/i_product_repository.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../domain/models/product.dart';

class ProductController extends GetxController {
  final RxList<Product> _products = <Product>[].obs;
  late IProductRepository repository;
  final RxBool isLoading = false.obs;
  List<Product> get products => _products;

  @override
  void onInit() {
    getProducts();
    super.onInit();
  }

  ProductController(this.repository);

  Future<void> getProducts() async {
    logInfo("ProductController: Getting products");
    isLoading.value = true;
    _products.value = await repository.getProducts();
    isLoading.value = false;
  }

  Future<void> addProduct(String name, String desc, String quantity) async {
    logInfo("ProductController: Add product");
    await repository.addProduct(
      Product(name: name, description: desc, quantity: int.parse(quantity)),
    );
    await getProducts();
  }

  Future<void> updateProduct(Product product) async {
    logInfo("ProductController: Update product");
    await repository.updateProduct(product);
    await getProducts();
  }

  Future<void> deleteProduct(Product p) async {
    logInfo("ProductController: Delete product");
    await repository.deleteProduct(p);
    await getProducts();
  }

  Future<void> deleteProducts() async {
    logInfo("ProductController: Delete all products");
    isLoading.value = true;
    await repository.deleteProducts();
    await getProducts();
    isLoading.value = false;
  }
}
```

**Key points:**
- Extends `GetxController`
- Private observable list: `RxList<T> _products = <T>[].obs`
- Public getter: `List<T> get products => _products`
- `isLoading` as `RxBool` for loading states
- Constructor receives `IProductRepository` (the abstraction)
- `onInit()` loads initial data, calls `super.onInit()` at the end
- Each write method calls `getProducts()` after to refresh the list
- Every method logs with `logInfo("ControllerName: Action description")`
- `addProduct` takes raw field values (strings) and constructs the model internally

---

## UI Layer — Views (General Conventions)

Location: `ui/views/[view_name]_page.dart`

Views are **not** prescriptive — their number and purpose depend on the feature's design. The developer decides what screens the feature needs. Each screen gets its own file in the `views/` folder.

What the skill **does** enforce is how view files are structured:

### File and class conventions
- One screen per file, named `[descriptive_name]_page.dart`
- Class name matches: `DescriptiveNamePage` (suffix `Page`)
- Use `StatefulWidget` when the view has form inputs (`TextEditingController`) or local state
- Use `StatelessWidget` for purely reactive views (only `Obx()` bindings)

### Accessing the controller
- Get the controller via `Get.find()` — never instantiate it in the view
- For `StatefulWidget`: assign in the `State` class body: `ProductController controller = Get.find();`
- For `StatelessWidget`: assign in `build()`: `final controller = Get.find<ProductController>();`

### Reactive UI
- Wrap reactive parts in `Obx(() => ...)` — this rebuilds automatically when observables change
- Use `controller.isLoading.value` for loading states (show `CircularProgressIndicator`)

### Navigation patterns
- Navigate forward: `Get.to(() => const SomePage())`
- Pass data to next page: `Get.to(() => const SomePage(), arguments: [item, item.id])`
- Receive data: `var item = Get.arguments[0];`
- Go back: `Get.back()`

### Error handling in views
- Wrap async operations in `try/catch`
- Show errors with: `Get.snackbar("Error", err.toString(), snackPosition: SnackPosition.BOTTOM)`

### Form input conventions
- Use `TextEditingController` for each input field
- `OutlineInputBorder` with `Radius.circular(20)` for text field borders
- `SizedBox(height: 20)` for spacing between fields
- `FilledButton.tonal` for primary actions (Save, Update, etc.)

---

## DI Registration in main.dart

New modules are registered in `main()` before `runApp()`. Follow this pattern:

```dart
// [Entity] — comment block to identify the section
Get.put<I[Entity]Source>(Local[Entity]Source());
// Or for remote: Get.put<I[Entity]Source>(Remote[Entity]Source(Get.find<http.Client>(tag: 'apiClient')));
Get.put<I[Entity]Repository>([Entity]Repository(Get.find()));
Get.lazyPut(() => [Entity]Controller(Get.find()));
```

**Key points:**
- Register data source first (typed as the abstract interface)
- Then repository (typed as abstract interface, receives source via `Get.find()`)
- Then controller via `Get.lazyPut` (receives repository via `Get.find()`)
- Add corresponding imports at the top of main.dart
- Keep a comment header (`// [Entity]`) for each module's section

---

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| File names | `snake_case` | `product_controller.dart` |
| Classes | `PascalCase` | `ProductController` |
| Variables | `camelCase` | `productController` |
| Private fields | `_camelCase` | `_products` |
| Abstract interfaces | `I` prefix | `IProductRepository` |
| Concrete classes | No prefix | `ProductRepository` |
| Controllers | `*Controller` suffix | `ProductController` |
| Pages/Views | `*Page` suffix | `ListProductPage` |
| Data sources | `Local*Source` / `Remote*Source` | `LocalProductSource` |
| Repositories | `*Repository` | `ProductRepository` |

---

## Import Conventions

Order imports in this sequence:
1. Package imports (`package:flutter/...`, `package:get/...`, `package:loggy/...`)
2. Project-level package imports (`package:f_clean_template/...`)
3. Relative imports (`../../domain/models/...`)

Within the domain layer, only use relative imports to other domain files.
Within the data layer, use relative imports to reach domain models and datasource interfaces.
Within the UI layer, use either package or relative imports.

Never import from the `data/` layer in the `domain/` layer — the dependency rule flows inward only.
