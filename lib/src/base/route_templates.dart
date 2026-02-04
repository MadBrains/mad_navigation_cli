import 'package:mad_navigation_cli/src/base/route_meta.dart';
import 'package:mad_scripts_base/mad_scripts_base.dart';

/// Provides small string templates used by the route generator.
///
/// Each method returns a **rendered string** built from a hand-rolled template
/// and substituted values via [ScriptTemplates.fromString]. These strings are
/// then inserted into project files by higher-level helpers such as
/// `AddRoute`/`SimpleAddRoute`.
///
/// The templates intentionally stay minimal to keep diffs readable.
class RouteTemplates {
  /// Renders a concrete route class declaration for the given [meta] and [routeName].
  ///
  /// Output example (for `meta.typeName='Page'`, `routeName='Settings'`):
  /// ```dart
  /// class PageSettings extends NavPage<Never> {
  ///   PageSettings() : super('settings');
  /// }
  /// ```
  ///
  /// Notes:
  /// - The template currently uses `Nav{{TYPE}}` as a base class,
  ///   even though [RouteMeta.baseClass] is provided to the values map.
  /// - The generic is taken from [RouteMeta.generic] (defaults to `'Never'`).
  static String routeClass({
    required RouteMeta meta,
    required String routeName,
  }) {
    const String _routeTemplate = '''
class {{TYPE}}{{NAME}} extends Nav{{TYPE}}<{{GENERIC}}> {
  {{TYPE}}{{NAME}}() : super('{{ROUTE_NAME}}');
}''';

    return ScriptTemplates.fromString(
      _routeTemplate,
      values: <String, dynamic>{
        'TYPE': meta.typeName,
        'NAME': routeName,
        'BASE_CLASS':
            meta.baseClass, // kept for compatibility, not used in template
        'GENERIC': meta.generic,
        'ROUTE_NAME': meta.routeName(routeName),
      },
    );
  }

  /// Renders a navigation service **method name** for the given route.
  ///
  /// Example for `meta.typeName='Page'`, `routeName='Settings'`:
  /// ```
  /// openPageSettings
  /// ```
  static String methodName({
    required RouteMeta meta,
    required String routeName,
  }) {
    const String _methodTemplate = '''open{{TYPE}}{{NAME}}''';

    return ScriptTemplates.fromString(
      _methodTemplate,
      values: <String, dynamic>{'TYPE': meta.typeName, 'NAME': routeName},
    );
  }

  /// Renders an **abstract** method signature for the navigation service.
  ///
  /// The return type is derived from [RouteMeta.methodGeneric]:
  /// - `'void'` when `generic == 'Never'`,
  /// - otherwise `'<Generic>?'` (nullable).
  ///
  /// Example:
  /// ```dart
  /// Future<void> openPageSettings();
  /// ```
  static String abstractServiceMethod({
    required RouteMeta meta,
    required String methodName,
  }) {
    const String _methodTemplate = '''
    Future<{{GENERIC}}> {{NAME}}();
    ''';

    return ScriptTemplates.fromString(
      _methodTemplate,
      values: <String, dynamic>{
        'NAME': methodName,
        'GENERIC': meta.methodGeneric,
      },
    );
  }

  /// Renders a **concrete** service implementation method that pushes the route.
  ///
  /// The push call switches between `pushToRoot` and `pushToCurrentTab`
  /// based on [RouteMeta.isInTab].
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<void> openPageSettings() =>
  ///     pushToRoot(PageSettings());
  /// ```
  static String serviceMethod({
    required RouteMeta meta,
    required String methodName,
    required String routeName,
  }) {
    const String _methodTemplate = '''
    @override
    Future<{{GENERIC}}> {{METHOD}}() => {{^isInTab}}pushToRoot{{/isInTab}}{{#isInTab}}pushToCurrentTab{{/isInTab}}({{TYPE}}{{NAME}}());
    ''';

    return ScriptTemplates.fromString(
      _methodTemplate,
      values: <String, dynamic>{
        'TYPE': meta.typeName,
        'NAME': routeName,
        'GENERIC': meta.methodGeneric,
        'METHOD': methodName,
        'isInTab': meta.isInTab,
      },
    );
  }

  /// Renders a **new mapper section** for a specific route type,
  /// including a `routes:` list with a single `MadRouteBuilder`.
  ///
  /// Use this when there is **no existing mapper** for `meta.typeName` yet.
  ///
  /// [uiComponent] should be a widget expression (e.g. `'SettingsPage()'`).
  /// If omitted, the current template will emit an **empty expression** after
  /// `=>`, which is invalid Dart — ensure the caller provides a value or
  /// adapt the template upstream to insert a safe default.
  ///
  /// Example output:
  /// ```dart
  /// PageMapper(
  ///   routes: <MadRouteBuilder<NavPage<dynamic>>>[
  ///     MadRouteBuilder<PageSettings>((_) => SettingsPage()),
  ///   ],
  /// ),
  /// ```
  static String newMapper({
    required RouteMeta meta,
    required String routeName,
    String? uiComponent,
  }) {
    final String _mapper =
        '''
    {{TYPE}}Mapper(
      routes: <MadRouteBuilder<Nav{{TYPE}}<dynamic>>>[MadRouteBuilder<{{TYPE}}{{NAME}}>((_) => ${uiComponent ?? ''})],
    ),
    ''';

    return ScriptTemplates.fromString(
      _mapper,
      values: <String, dynamic>{'TYPE': meta.typeName, 'NAME': routeName},
    );
  }

  /// Renders a **single builder entry** for an existing mapper’s `routes:` list.
  ///
  /// Use this when a mapper for `meta.typeName` already exists, and you only
  /// need to append one more `MadRouteBuilder`.
  ///
  /// [uiComponent] should be a widget expression (e.g. `'SettingsPage()'`).
  /// If omitted, the current template will emit an **empty expression** after
  /// `=>`, which is invalid Dart — ensure the caller provides a value or
  /// adapt the template upstream to insert a safe default.
  ///
  /// Example:
  /// ```dart
  /// MadRouteBuilder<PageSettings>((_) => SettingsPage()),
  /// ```
  static String mapper({
    required RouteMeta meta,
    required String routeName,
    String? uiComponent,
  }) {
    final String _mapper =
        '''MadRouteBuilder<{{TYPE}}{{NAME}}>((_) => ${uiComponent ?? ''}),''';

    return ScriptTemplates.fromString(
      _mapper,
      values: <String, dynamic>{'TYPE': meta.typeName, 'NAME': routeName},
    );
  }
}
