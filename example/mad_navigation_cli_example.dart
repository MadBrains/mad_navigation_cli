// Usage examples for the route generation utilities:
// 1) Create a custom RouteMeta and run the full flow via SimpleAddRoute.
// 2) Create a custom AddRoute subclass to adjust behavior.
// 3) Call AddRoute directly to perform only parts of the pipeline.
//
// Notes:
// - Make sure your config file paths in AddRouteConfig are correct for your repo.
// - uiComponent should be a valid widget expression string (e.g., 'SettingsPage()').
// - Exceptions are typed (see add_route_exceptions.dart).

import 'package:mad_navigation_cli/mad_navigation_cli.dart';
import 'package:mad_scripts_base/mad_scripts_base.dart';

Future<void> main(List<String> args) async {
  // Choose what to run — for demo purposes we call all three sequentially.
  // In real usage, pick one scenario.
  await customMeta();
  await customAddRoute();
  await rawUseAddRoute();
}

/// ---------------------------------------------------------------------------
/// 1) Define your own RouteMeta and run via SimpleAddRoute
/// ---------------------------------------------------------------------------
/// This is the most convenient “one-shot” way to create a route:
/// - inserts the route class,
/// - optionally updates services,
/// - updates the route mapper.
Future<void> customMeta() async {
  // Load config from file. Adjust the path to your setup.
  final AddRouteConfig config = ConfigReader.fromFile(
    'mad_navigation.json',
    transformer: AddRouteConfig.fromJson,
  );

  // Define a custom route meta (you may also use RouteMetas.page/dialog/bottomSheet/tabHolder).
  const RouteMeta meta = RouteMeta(baseClass: 'MyPage', typeName: 'MyPageType');

  // Create a simple orchestrator and run full flow.
  const String routeName = 'Settings';
  final SimpleAddRoute add = SimpleAddRoute(
    routeName: routeName,
    config: config,
    meta: meta,
  );

  try {
    await add.run(uiComponent: 'SettingsPage()');
    output.success('example1: Settings route added.');
  } on AddRouteException catch (e) {
    // Handle typed exceptions nicely
    output.error('example1: ${e.runtimeType}: ${e.message}');
  }
}

/// ---------------------------------------------------------------------------
/// 2) Create your own AddRoute subclass
/// ---------------------------------------------------------------------------
/// Useful when you want to adjust WHERE/HOW things are inserted
/// (e.g., custom heuristics, logging, formatting, templates).
class CustomAddRoute extends AddRoute {
  const CustomAddRoute({
    required super.routeName,
    required super.config,
    required super.meta,
  });

  Future<void> run() async {
    // 1) Insert just the route class (you could also do full flow manually if desired)
    await addRouteClass(
      renderedTemplate: RouteTemplates.routeClass(
        meta: meta,
        routeName: routeName,
      ),
      baseClass: meta.baseClass,
    );

    // 2) Add to services (abstract + impl)
    final String method = RouteTemplates.methodName(
      meta: meta,
      routeName: routeName,
    );
    await addToService(
      renderedServiceTemplate: RouteTemplates.abstractServiceMethod(
        meta: meta,
        methodName: method,
      ),
      renderedServiceImplTemplate: RouteTemplates.serviceMethod(
        meta: meta,
        methodName: method,
        routeName: routeName,
      ),
    );

    // 3) Add to mapper with a custom component
    await addMapper(
      fullNewMapperTemplate: RouteTemplates.newMapper(
        meta: meta,
        routeName: routeName,
        uiComponent: 'ConfirmSignOutDialog()',
      ),
      renderedTemplate: RouteTemplates.mapper(
        meta: meta,
        routeName: routeName,
        uiComponent: 'ConfirmSignOutDialog()',
      ),
    );
  }

  /// Example: add logging and/or custom formatting, or post-process rendered code.
  @override
  Future<void> addToService({
    required String renderedServiceTemplate,
    required String renderedServiceImplTemplate,
  }) async {
    // pre-processing / logging
    output.info('[CustomAddRoute] Adding service methods for $routeName ...');
    await super.addToService(
      renderedServiceTemplate: renderedServiceTemplate,
      renderedServiceImplTemplate: renderedServiceImplTemplate,
    );
    // post-processing could be added here (e.g., run formatter, lints, etc.)
  }
}

Future<void> customAddRoute() async {
  final AddRouteConfig config = ConfigReader.fromFile(
    'mad_navigation.json',
    transformer: AddRouteConfig.fromJson,
  );

  // Suppose we want a dialog returning a bool? result.
  const RouteMeta meta = RouteMeta(
    typeName: 'Dialog',
    baseClass: 'NavDialog',
    generic: 'bool',
  );

  const String routeName = 'ConfirmSignOut';

  final CustomAddRoute add = CustomAddRoute(
    routeName: routeName,
    config: config,
    meta: meta,
  );

  try {
    await add.run();
    output.success('example2: Custom dialog route added.');
  } on AddRouteException catch (e) {
    output.error('example2: ${e.runtimeType}: ${e.message}');
  }
}

/// ---------------------------------------------------------------------------
/// 3) Use AddRoute directly for partial operations
/// ---------------------------------------------------------------------------
/// Sometimes you only need a part of the pipeline, e.g., just add a mapper
/// entry for an already existing route class, or only add service methods.
Future<void> rawUseAddRoute() async {
  final AddRouteConfig config = ConfigReader.fromFile(
    'mad_navigation.json',
    transformer: AddRouteConfig.fromJson,
  );

  // Let’s say the class already exists, we only need to append a mapper entry.
  const RouteMeta meta = RouteMeta(
    typeName: 'BottomSheet',
    baseClass: 'NavBottomSheet',
  );

  const String routeName = 'SelectTheme';

  final AddRoute partial = AddRoute(
    routeName: routeName,
    config: config,
    meta: meta,
  );

  try {
    // CASE A: Only mapper
    await partial.addMapper(
      fullNewMapperTemplate: RouteTemplates.newMapper(
        meta: meta,
        routeName: routeName,
        uiComponent: 'SelectThemeSheet()',
      ),
      renderedTemplate: RouteTemplates.mapper(
        meta: meta,
        routeName: routeName,
        uiComponent: 'SelectThemeSheet()',
      ),
    );

    // CASE B: Only services (uncomment if needed)
    // final String method = RouteTemplates.methodName(meta: meta, routeName: routeName);
    // await partial.addToService(
    //   renderedServiceTemplate: RouteTemplates.abstractServiceMethod(meta: meta, methodName: method),
    //   renderedServiceImplTemplate: RouteTemplates.serviceMethod(
    //     meta: meta,
    //     methodName: method,
    //     routeName: routeName,
    //   ),
    // );

    output.success('example3: Mapper appended for BottomSheet route.');
  } on AddRouteException catch (e) {
    output.error('example3: ${e.runtimeType}: ${e.message}');
  }
}
