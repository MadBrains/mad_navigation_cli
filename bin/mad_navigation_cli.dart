import 'package:mad_navigation_cli/mad_navigation_cli.dart';
import 'package:mad_scripts_base/mad_scripts_base.dart';

void main(List<String> arguments) {
  CommandRunner<bool>('mad_navigation_cli', 'Scripts to Mad Navigation Package')
    ..addCommand(AddRouteCommand())
    ..run(arguments);
}
