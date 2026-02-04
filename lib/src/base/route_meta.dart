import 'package:mad_scripts_base/mad_scripts_base.dart';

/// Describes metadata for a specific route type.
///
/// A [RouteMeta] defines the base class, generic type, and routing behavior
/// for generated navigation entities. It provides a consistent structure
/// for all types of routes (pages, dialogs, bottom sheets, etc.)
/// used by the navigation code generator.
///
/// Example:
/// ```dart
/// const RouteMeta(
///   typeName: 'Page',
///   baseClass: 'NavPage',
///   generic: 'UserModel',
///   isInTab: false,
/// );
/// ```
class RouteMeta {
  /// Creates a new route metadata descriptor.
  ///
  /// The [typeName] and [baseClass] parameters are required.
  /// The [generic] type defaults to `'Never'`, and [isInTab] defaults to `false`.
  const RouteMeta({
    this.typeName = '',
    required this.baseClass,
    this.isInTab = false,
    this.generic = _defaultGeneric,
  });

  /// The default generic type used when no specific generic is provided.
  static const String _defaultGeneric = 'Never';

  /// The type name for this route, such as `'Page'`, `'Dialog'`, or `'BottomSheet'`.
  ///
  /// This name is used for code generation (e.g., class and method names).
  ///
  /// Example:
  /// ```dart
  /// // Generates: class PageProfile extends NavPage<Never> { ... }
  /// final typeName = 'Page';
  /// ```
  final String typeName;

  /// The base navigation class used as a superclass for generated routes.
  ///
  /// Example values include `'NavPage'`, `'NavDialog'`, `'NavBottomSheet'`, etc.
  final String baseClass;

  /// The generic type parameter for the route class.
  ///
  /// Defaults to `'Never'`.
  /// If a route returns a result, specify the type here (e.g., `'UserModel'`).
  ///
  /// Example:
  /// ```dart
  /// const RouteMeta(
  ///   typeName: 'Dialog',
  ///   baseClass: 'NavDialog',
  ///   generic: 'bool',
  /// );
  /// ```
  final String generic;

  /// Whether this route is intended to be used inside a tab navigation context.
  ///
  /// If `true`, generated navigation methods will use
  /// `pushToCurrentTab()` instead of `pushToRoot()`.
  final bool isInTab;

  /// The appropriate generic type to use in navigation method signatures.
  ///
  /// - Returns `'void'` if the route’s generic is `'Never'`.
  /// - Returns `'T?'` (nullable) if a specific generic type is provided.
  ///
  /// Example:
  /// ```dart
  /// // Never -> void
  /// RouteMeta.page.methodGeneric == 'void';
  ///
  /// // bool -> bool?
  /// RouteMeta.dialog.methodGeneric == 'bool?';
  /// ```
  String get methodGeneric => generic == _defaultGeneric ? 'void' : '$generic?';

  /// Converts a raw route name into a kebab-case string for URL or ID usage.
  ///
  /// Example:
  /// ```dart
  /// meta.routeName('UserProfile'); // → 'user-profile'
  /// ```
  String routeName(String raw) => raw.toKebabCase;
}

/// A collection of predefined [RouteMeta] configurations
/// for the most common route types.
///
/// These constants can be used directly when creating routes
/// through the CLI or in automation scripts.
///
/// Example:
/// ```dart
/// final meta = RouteMetas.page;
/// print(meta.baseClass); // → 'NavPage'
/// ```
abstract final class RouteMetas {
  /// Metadata for a standard page route.
  static const RouteMeta page = RouteMeta(
    typeName: 'Page',
    baseClass: 'NavPage',
  );

  /// Metadata for a bottom sheet route.
  static const RouteMeta bottomSheet = RouteMeta(
    typeName: 'BottomSheet',
    baseClass: 'NavBottomSheet',
  );

  /// Metadata for a dialog route.
  static const RouteMeta dialog = RouteMeta(
    typeName: 'Dialog',
    baseClass: 'NavDialog',
  );

  /// Metadata for a tab holder route, typically used for tab containers.
  static const RouteMeta tabHolder = RouteMeta(
    typeName: 'TabHolder',
    baseClass: 'NavTabHolder',
    isInTab: true,
  );
}
