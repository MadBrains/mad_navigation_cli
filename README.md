# Mad Navigation CLI

A command-line utility for automatic generation and registration of navigation routes  
in **Flutter** projects using the [mad_scripts_base](https://pub.dev/packages/mad_scripts_base) and [mad_navigation](https://pub.dev/packages/mad_navigation).

It automates:

- 🏗️ Creating new route classes (`Page`, `Dialog`, `BottomSheet`, `TabHolder`);
- 🧩 Updating the route mapper (`MadRouteMapper`);
- 🔧 Extending navigation services with new methods.

---

## 🚀 Quick Start (CLI)

Add the package as a dependency to your scripts project:

```bash
dart pub add mad_navigation_cli
```

Then run the built-in command via the **mad scripts CLI**:

```bash
mad add_route --page --name Settings --uiComponent SettingsPage()
```

Supported route types (choose one flag):

| Flag | Description |
|------|--------------|
| `--page` | Standard full-screen page |
| `--dialog` | Dialog that may return a result |
| `--bottomSheet` | Bottom sheet component |
| `--tabHolder` | Container route used inside tab navigation |

Example:

```bash
mad add_route --dialog --name ConfirmSignOut --uiComponent ConfirmSignOutDialog()
```

This will:

1. Insert a new `DialogConfirmSignOut` class into your routes file;
2. Add an abstract method + implementation to navigation services;
3. Register a new builder entry in the route mapper.

---

## 🧠 Advanced Usage in Custom Scripts

You can reuse `AddRoute`, `SimpleAddRoute`, or even subclass them  
inside your own **mad_scripts_base** commands.

### Example 1: Full automation with `SimpleAddRoute`

```dart
final AddRouteConfig config =
    ConfigReader.fromFile('mad_navigation.json', transformer: AddRouteConfig.fromJson);

const RouteMeta meta = RouteMetas.page;

final SimpleAddRoute add = SimpleAddRoute(
  routeName: 'Settings',
  config: config,
  meta: meta,
);

await add.run(uiComponent: 'SettingsPage()');
```

### Example 2: Extend `AddRoute` for custom behavior

```dart
class CustomAddRoute extends AddRoute {
  const CustomAddRoute({
    required super.routeName,
    required super.config,
    required super.meta,
  });

  @override
  Future<void> addToService({
    required String renderedServiceTemplate,
    required String renderedServiceImplTemplate,
  }) async {
    print('[CustomAddRoute] Adding service methods for $routeName ...');
    await super.addToService(
      renderedServiceTemplate: renderedServiceTemplate,
      renderedServiceImplTemplate: renderedServiceImplTemplate,
    );
  }
}
```

### Example 3: Partial usage

Call only what you need — for instance, update just the mapper:

```dart
final AddRoute add = AddRoute(routeName: 'SelectTheme', config: config, meta: RouteMetas.bottomSheet);

await add.addMapper(
  fullNewMapperTemplate: RouteTemplates.newMapper(
    meta: RouteMetas.bottomSheet,
    routeName: 'SelectTheme',
    uiComponent: 'SelectThemeSheet()',
  ),
  renderedTemplate: RouteTemplates.mapper(
    meta: RouteMetas.bottomSheet,
    routeName: 'SelectTheme',
    uiComponent: 'SelectThemeSheet()',
  ),
);
```

For more complex examples see [`example.dart`](example.dart).

---

## ⚙️ Configuration

Routes, mappers, and service file paths are defined in your project’s
`mad_navigation.json` (parsed into `AddRouteConfig`):

```json
{
  "routesPath": "lib/navigation/app_routes.dart",
  "routeMapperPath": "lib/navigation/app_mapper.dart",
  "servicePath": "lib/navigation/navigation_service.dart",
  "serviceImplPath": "lib/navigation/navigation_service_impl.dart",
  "addToService": true
}
```

---

## 🚨 Error Handling

All runtime errors during file parsing or modification throw typed exceptions:

| Exception | Meaning |
|------------|----------|
| `RouteInsertionException` | No matching base class found to insert route |
| `MapperNotFoundException` | Mapper class (e.g. `MadRouteMapper`) not found |
| `RoutersMethodInvalidException` | `routers()` method has invalid or unexpected body |
| `ServiceInsertionException` | Service or implementation class not found |

You can catch them easily:

```dart
try {
  await add.run();
} on AddRouteException catch (e) {
  print('Failed: ${e.runtimeType} → ${e.message}');
}
```

---

## 🧱 Architecture Overview

| Component | Responsibility |
|------------|----------------|
| `AddRoute` | Core low-level logic — AST parsing, code insertion |
| `SimpleAddRoute` | High-level orchestrator combining templates & logic |
| `RouteMeta` / `RouteMetas` | Describes route types (`Page`, `Dialog`, etc.) |
| `RouteTemplates` | String templates for classes, mappers, and services |
| `AddRouteCommand` | CLI command wrapper used by `mad_scripts` |

---

## 💬 Feedback

This package is part of the Mad Scripts ecosystem.  
If you encounter edge cases or need extended automation support,  
feel free to open an issue or propose an enhancement.

---

**Author:** Mad Brains  
**License:** MIT
