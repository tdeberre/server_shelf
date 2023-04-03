import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'game.dart';
import 'api.dart';

class ClientManager {
  static init() async {
    final ip = InternetAddress.anyIPv4;
    final port = int.parse(Platform.environment['PORT'] ?? '56562');
    final server = await ServerSocket.bind(ip, port);
    server.listen((client) {
      handleConnection(client);
    });
    print("ClientManager listening on port ${server.port}");
  }

  static void handleConnection(Socket client) async {
    client.listen(
      (Uint8List data) async {
        final clientRequest = jsonDecode(String.fromCharCodes(data));
        try {
          final String username = tokens.entries
              .firstWhere((e) => e.value["token"] == clientRequest["token"])
              .key;
          List<String> deck = clientRequest['deck'].cast<String>();
          Player player = Player(player: username, socket: client, deck: deck);
          Player? enemy;
          try {
            enemy = players.firstWhere((e) => e.enemy == null);
          } catch (e) {
            player.enemy = null;
            print("enemy: $e");
          }
          if (enemy != null) {
            player.enemy = enemy.player;
            enemy.enemy = player.player;
          }
          players.removeWhere((e) => e.player == player.player);
          players.add(player);
          if (enemy != null) {
            player.sendNewState();
          }
        } catch (e) {
          print(e);
          client.close();
        }
      },
      onError: (error) {
        print(error);
        client.close();
      },
      onDone: () {
        client.close();
      },
    );
  }

  static bool connectionCheck(Map clientCreds, Socket thisSocket) {
    final data = File("bin/data/users.json").readAsStringSync();
    final user = jsonDecode(data)[clientCreds['name']];
    if (user['pwd'] == clientCreds["pwd"]) {
    } else {
      throw "wrong password";
    }
    return true;
  }
}
