import 'clientmanager.dart';
import 'api.dart';
import 'site.dart';

void main(List<String> args) {
  Api.init();
  ClientManager.init();
  Site.init();
}
