import 'package:mad_navigation_cli/mad_navigation_cli.dart';

/// A high-level orchestrator that generates and wires up a single route:
/// - creates the route class,
/// - (optionally) updates navigation services,
/// - updates the route mapper.
///
/// This class is a thin convenience wrapper over [AddRoute] + [RouteTemplates].
/// It is intended for “one-shot” route creation where defaults are acceptable.
///
/// Example:
/// ```dart
/// final config = ConfigReader.fromFile('mad_navigation.json', transformer: AddRouteConfig.fromJson);
/// const meta = RouteMetas.page; // Page/Dialog/BottomSheet/TabHolder
/// const add = SimpleAddRoute(routeName: 'Settings', config: config, meta: meta);
///
/// await add.run(uiComponent: 'SettingsPage()');
/// ```
///
/// Throws:
/// - [RouteInsertionException] if the route class cannot be inserted;
/// - [ServiceInsertionException] if service or implementation cannot be updated;
/// - [MapperNotFoundException] / [RoutersMethodInvalidException] if mapper insertion fails.
class SimpleAddRoute extends AddRoute {
  /// Creates a simple route generator.
  ///
  /// - [routeName] is a PascalCase name used for class/method generation (e.g., `Settings`).
  /// - [config] provides file paths and generation flags.
  /// - [meta] describes route type (page/dialog/bottom sheet/tab holder).
  const SimpleAddRoute({required super.routeName, required super.config, required super.meta});

  /// Executes the full route creation pipeline:
  ///
  /// 1. **Route class** — inserts a `{{TYPE}}{{NAME}}` class into the routes file.
  /// 2. **Service & impl (optional)** — if `config.addToService == true`, adds:
  ///    - abstract method to the navigation service,
  ///    - method implementation to the navigation service implementation.
  /// 3. **Mapper** — appends either a new mapper section for this `TYPE`,
  ///    or adds a new `MadRouteBuilder` into the existing mapper’s `routes:` list.
  ///
  /// [uiComponent] — optional widget/expression used inside the `MadRouteBuilder`,
  /// e.g. `'SettingsPage()'`. If omitted, your template should handle a safe default.
  ///
  /// Throws the typed exceptions documented on the class if any step fails.
  Future<void> run({String? uiComponent}) async {
    // 1) Insert the route class
    await addRouteClass(
      renderedTemplate: RouteTemplates.routeClass(meta: meta, routeName: routeName),
      baseClass: meta.baseClass,
    );

    // 2) Update navigation services if enabled
    if (config.addToService) {
      final String methodName = RouteTemplates.methodName(meta: meta, routeName: routeName);

      await addToService(
        renderedServiceTemplate: RouteTemplates.abstractServiceMethod(meta: meta, methodName: methodName),
        renderedServiceImplTemplate: RouteTemplates.serviceMethod(
          meta: meta,
          methodName: methodName,
          routeName: routeName,
        ),
      );
    }

    // 3) Update route mapper
    await addMapper(
      fullNewMapperTemplate: RouteTemplates.newMapper(meta: meta, routeName: routeName, uiComponent: uiComponent),
      renderedTemplate: RouteTemplates.mapper(meta: meta, routeName: routeName, uiComponent: uiComponent),
    );
  }
}
