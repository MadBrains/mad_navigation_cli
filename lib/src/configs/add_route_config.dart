class AddRouteConfig {
  const AddRouteConfig({
    required this.serviceImplPath,
    required this.servicePath,
    required this.routeMapperPath,
    required this.addToService,
    required this.routesPath,
  });

  factory AddRouteConfig.fromJson(Map<String, dynamic> json) {
    return AddRouteConfig(
      serviceImplPath: json['serviceImplPath'] as String?,
      servicePath: json['servicePath'] as String?,
      routeMapperPath: json['routeMapperPath'] as String,
      addToService: json['addToService'] as bool,
      routesPath: json['routesPath'] as String,
    );
  }

  final String? serviceImplPath;
  final String? servicePath;
  final String routeMapperPath;
  final bool addToService;
  final String routesPath;
}
