import 'package:mad_navigation_cli/mad_navigation_cli.dart';
import 'package:mad_scripts_base/mad_scripts_base.dart';

class AddRouteCommand extends ScriptCommand<bool> {
  AddRouteCommand() {
    argParser.addFlag(
      'page',
      callback: (bool value) {
        page = value;
      },
    );

    argParser.addFlag(
      'bottomSheet',
      callback: (bool value) {
        bottomSheet = value;
      },
    );

    argParser.addFlag(
      'dialog',
      callback: (bool value) {
        dialog = value;
      },
    );

    argParser.addFlag(
      'tabHolder',
      callback: (bool value) {
        tabHolder = value;
      },
    );

    argParser.addOption(
      'name',
      mandatory: true,
      callback: (String? value) {
        routeName = value;
      },
    );

    argParser.addOption(
      'uiComponent',
      callback: (String? value) {
        uiComponent = value;
      },
    );
  }

  @override
  String get description => 'Add route to mapper and service';

  @override
  String get name => 'add_route';

  bool page = false;
  bool bottomSheet = false;
  bool dialog = false;
  bool tabHolder = false;
  String? routeName;
  String? uiComponent;

  @override
  Future<bool> runWrapped() async {
    output.info('Stable support for $stablePackageSupportVersion');
    output.debug('Page Route: $page');
    output.debug('BottomSheet Route: $bottomSheet');
    output.debug('Dialog Route: $dialog');
    output.debug('Tab Holder Route: $tabHolder');
    final int trueCount = <bool>[
      page,
      bottomSheet,
      dialog,
      tabHolder,
    ].where((bool e) => e).length;
    if (trueCount == 0) {
      output.error(
        'Need route type. Choose one: --page, --bottomSheet, --dialog, --tabHolder',
      );

      return false;
    }
    if (trueCount >= 2) {
      output.error('Select more then one route type');
      return false;
    }

    final AddRouteConfig config = ConfigReader.fromFile(
      configPath ?? '',
      transformer: AddRouteConfig.fromJson,
    );

    final SimpleAddRoute addRoute = SimpleAddRoute(
      routeName: routeName ?? '',
      config: config,
      meta: _routeMeta,
    );

    await addRoute.run(uiComponent: uiComponent);

    return true;
  }

  RouteMeta get _routeMeta {
    if (page) return RouteMetas.page;
    if (bottomSheet) return RouteMetas.bottomSheet;
    if (dialog) return RouteMetas.dialog;

    return RouteMetas.tabHolder;
  }
}
