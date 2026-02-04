import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:mad_navigation_cli/mad_navigation_cli.dart';
import 'package:mad_scripts_base/mad_scripts_base.dart';

typedef ClassWhere = bool Function(ClassDeclaration c);

/// A utility class responsible for inserting a new navigation route
/// into an existing project structure.
///
/// It automates:
/// 1. Adding a new route class to the routes file.
/// 2. Updating the route mapper with the new route.
/// 3. Adding abstract and implementation methods to navigation services.
///
/// This class operates by analyzing and modifying Dart source files
/// using the `analyzer` package.
class AddRoute {
  const AddRoute({
    required this.routeName,
    required this.config,
    required this.meta,
  });

  /// The raw route name (e.g., `Settings`, `Profile`, `MainTab`).
  final String routeName;

  /// Metadata describing the type of route being added
  /// (e.g., `Page`, `Dialog`, `BottomSheet`).
  final RouteMeta meta;

  /// Configuration object containing file paths and generation options.
  final AddRouteConfig config;

  /// The name of the base navigation service class.
  static const String serviceName = 'MadNavigationService';

  /// The name of the tab-based navigation service class.
  static const String tabServiceName = 'MadTabNavigationService';

  /// The name of the main route mapper class.
  static const String routerMapperName = 'MadRouteMapper';

  /// The name of the argument that holds route definitions inside mappers.
  static const String routerList = 'routers';

  /// The name of the arguments that holds MadRouteBuilder
  static const String routesArgs = 'routes';

  /// Inserts a new route class into the routes file.
  ///
  /// Finds the last class that extends [baseClass] and appends the
  /// rendered template immediately after it.
  ///
  /// Throws a [RouteInsertionException] if no matching class is found.
  Future<void> addRouteClass({
    required String renderedTemplate,
    required String baseClass,
  }) async {
    final String routesPath = config.routesPath;
    await FileManager(routesPath).updateFile(
      content: _insertAfterLastRoute(
        routesPath: routesPath,
        renderedTemplate: renderedTemplate,
        baseClass: baseClass,
      ),
      dirPathContainsFile: true,
    );
  }

  /// Inserts a new route mapping entry into the route mapper file.
  ///
  /// If a corresponding mapper type (e.g., `PageMapper`, `DialogMapper`)
  /// already exists, the new route is appended inside its `routes:` list.
  /// Otherwise, a new mapper section is created.
  ///
  /// Throws a [MapperNotFoundException] or [RoutersMethodInvalidException] if insertion fails.
  Future<void> addMapper({
    required String fullNewMapperTemplate,
    required String renderedTemplate,
  }) async {
    await FileManager(config.routeMapperPath).updateFile(
      content: _insertPageMapper(
        fullNewMapperTemplate: fullNewMapperTemplate,
        renderedTemplate: renderedTemplate,
      ),
      dirPathContainsFile: true,
    );
  }

  /// Adds a new navigation method to both the abstract navigation service
  /// and its concrete implementation.
  ///
  /// - [renderedServiceTemplate] — template for the abstract method.
  /// - [renderedServiceImplTemplate] — template for the implementation.
  ///
  /// Throws a [ServiceInsertionException] if insertion fails for any file.
  Future<void> addToService({
    required String renderedServiceTemplate,
    required String renderedServiceImplTemplate,
  }) async {
    await FileManager(config.servicePath ?? '').updateFile(
      dirPathContainsFile: true,
      content: _insertAfterLastMethod(
        servicePath: config.servicePath ?? '',
        renderedTemplate: renderedServiceTemplate,
        where: _implementsAny(<String>[serviceName, tabServiceName]),
      ),
    );

    const String impl = 'Impl';
    await FileManager(config.serviceImplPath ?? '').updateFile(
      dirPathContainsFile: true,
      content: _insertAfterLastMethod(
        servicePath: config.serviceImplPath ?? '',
        renderedTemplate: renderedServiceImplTemplate,
        where: _extendsOneOf(<String>[
          '$serviceName$impl',
          '$tabServiceName$impl',
        ]),
      ),
    );
  }

  /// Inserts a new route class right after the last class
  /// extending the given [baseClass].
  ///
  /// Returns the modified file content.
  ///
  /// Throws [RouteInsertionException] when target class is not found.
  String _insertAfterLastRoute({
    required String routesPath,
    required String renderedTemplate,
    required String baseClass,
  }) {
    final ClassDeclaration? declaration = _findDeclaration(
      path: routesPath,
      where: _extendsContains(baseClass),
    );
    if (declaration == null) {
      throw RouteInsertionException(routesPath);
    }

    final String content = File(routesPath).readAsStringSync();
    final int endOffset = declaration.end;

    return '${content.substring(0, endOffset)}\n\n$renderedTemplate${content.substring(endOffset)}';
  }

  /// Inserts a new method into the last class that matches [where].
  ///
  /// Used when adding navigation methods to a service or implementation file.
  ///
  /// Throws [ServiceInsertionException] when target class is not found.
  String _insertAfterLastMethod({
    required String servicePath,
    required String renderedTemplate,
    required ClassWhere where,
  }) {
    final ClassDeclaration? declaration = _findDeclaration(
      path: servicePath,
      where: where,
    );
    if (declaration == null) {
      throw ServiceInsertionException(servicePath);
    }

    final String content = File(servicePath).readAsStringSync();
    final int endOffset = declaration.endToken.offset;

    return '${content.substring(0, endOffset)}\n$renderedTemplate\n${content.substring(endOffset)}';
  }

  /// Finds the last class in the given file that satisfies [where].
  ///
  /// Returns `null` if no matching class is found.
  ClassDeclaration? _findDeclaration({
    required String path,
    required ClassWhere where,
  }) {
    final SomeParsedUnitResult unitResult = AnalyzerUtils.getParsedUnit(path);
    if (unitResult is ParsedUnitResult) {
      final CompilationUnit unit = unitResult.unit;
      final NodeList<CompilationUnitMember> declarations = unit.declarations;

      if (declarations.isNotEmpty) {
        final ClassDeclaration? lastClass = unit.declarations
            .whereType<ClassDeclaration>()
            .where(where)
            .lastWhereOrNull((_) => true);

        return lastClass;
      }
    }

    return null;
  }

  /// Inserts a new route entry inside the `routers` list of the route mapper.
  ///
  /// If a mapper for the current [meta.typeName] already exists,
  /// the route is added to its internal list.
  /// Otherwise, a new mapper section is appended at the end.
  ///
  /// Throws [MapperNotFoundException] if the mapper class is missing,
  /// or [RoutersMethodInvalidException] if the `routers` body/structure is invalid.
  String _insertPageMapper({
    required String fullNewMapperTemplate,
    required String renderedTemplate,
  }) {
    final ClassDeclaration? declaration = _findDeclaration(
      path: config.routeMapperPath,
      where: _extendsContains(routerMapperName),
    );
    if (declaration == null) {
      throw MapperNotFoundException(config.routeMapperPath);
    }

    final FunctionBody? routers = declaration.getFunctionBodyByName(routerList);
    final ExpressionFunctionBody? body = routers?.getExpressionBody();
    if (body == null) {
      throw RoutersMethodInvalidException(config.routeMapperPath);
    }
    final Expression expression = body.expression;
    if (expression is! ListLiteral) {
      throw RoutersMethodInvalidException(config.routeMapperPath);
    }
    for (final CollectionElement element in expression.elements) {
      if (element is! MethodInvocation) continue;

      // If we find the correct mapper type, try to insert into its routes list
      if (element.methodName.name.startsWith(meta.typeName)) {
        for (final Expression args in element.argumentList.arguments) {
          final NamedExpression? named = args
              .getNodeOfExactType<NamedExpression>();
          if (named == null) continue;

          final String name = named.name.label.name;
          if (name != routesArgs) continue;

          final ListLiteral? list = named.expression
              .getNodeOfExactType<ListLiteral>();
          if (list == null) continue;

          final String content = File(
            config.routeMapperPath,
          ).readAsStringSync();
          final int endOffset = list.rightBracket.offset;

          return '${content.substring(0, endOffset)}$renderedTemplate\n${content.substring(endOffset)}';
        }
      }
    }

    // Mapper type not found in list → append a new mapper section at the end.
    final String content = File(config.routeMapperPath).readAsStringSync();
    final int endOffset = expression.rightBracket.offset;
    return '${content.substring(0, endOffset)}$fullNewMapperTemplate\n${content.substring(endOffset)}';
  }

  /// Returns a predicate that matches any class extending one of [names].
  ClassWhere _extendsOneOf(List<String> names) {
    return (ClassDeclaration c) {
      final String? ext = c.extendsClause?.superclass.name.lexeme;
      if (ext == null) return false;
      return names.contains(ext);
    };
  }

  /// Returns a predicate that matches any class whose superclass name
  /// contains the given [text].
  ClassWhere _extendsContains(String text) {
    return (ClassDeclaration c) =>
        c.extendsClause?.superclass.toString().contains(text) ?? false;
  }

  /// Returns a predicate that matches classes implementing any of [names].
  ClassWhere _implementsAny(List<String> names) {
    return (ClassDeclaration c) {
      final List<NamedType> impl =
          c.implementsClause?.interfaces ?? const <NamedType>[];
      return impl.any(
        (NamedType interface) => names.contains(interface.name.lexeme),
      );
    };
  }
}
