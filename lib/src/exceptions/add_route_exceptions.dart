import 'package:mad_scripts_base/mad_scripts_base.dart';

/// The base class for all errors thrown during the route addition process.
///
/// Every specific exception (e.g. when a route, mapper, or service cannot
/// be found) extends this class. It inherits from [ScriptException]
/// for consistency with other Mad Scripts errors.
abstract class AddRouteException extends ScriptException {
  AddRouteException(super.message);
}

/// Thrown when a route class could not be found or inserted
/// into the target routes file.
///
/// Typically occurs when `_findDeclaration` cannot locate a class
/// extending the expected base class (e.g. `NavPage` or `NavDialog`).
class RouteInsertionException extends AddRouteException {
  /// Creates a new [RouteInsertionException].
  ///
  /// [path] should contain the file path where the insertion failed.
  RouteInsertionException(String path)
    : super("Can't insert new page in $path");
}

/// Thrown when a suitable mapper class (extending `MadRouteMapper`)
/// cannot be found in the route mapper file.
///
/// This usually indicates that the mapper file is missing the expected
/// class or has a nonstandard structure.
class MapperNotFoundException extends AddRouteException {
  /// Creates a new [MapperNotFoundException].
  ///
  /// [path] is the mapper file where the failure occurred.
  MapperNotFoundException(String path)
    : super("Can't find or insert page mapper in $path");
}

/// Thrown when the `routers` method in the mapper file
/// has an unexpected or unsupported body structure.
///
/// For example, if the method body is not an expression
/// or block returning a `ListLiteral`.
class RoutersMethodInvalidException extends AddRouteException {
  /// Creates a new [RoutersMethodInvalidException].
  ///
  /// [path] identifies the mapper file where parsing failed.
  RoutersMethodInvalidException(String path)
    : super("Invalid 'routers' method body structure in $path");
}

/// Thrown when a navigation service class could not be found
/// in either the abstract service or its implementation.
///
/// Usually occurs if the target file does not contain a class
/// implementing or extending the expected navigation service.
class ServiceInsertionException extends AddRouteException {
  /// Creates a new [ServiceInsertionException].
  ///
  /// [path] is the service file that failed to update.
  ServiceInsertionException(String path)
    : super("Can't insert new method in $path");
}
