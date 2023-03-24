import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'game.dart';
import 'api.dart';

Player? _pending;

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
        print(clientRequest);
        try {
          final token = tokens.entries
              .firstWhere((e) => e.value["token"] == clientRequest["token"]);
          Player player = Player(
              player: token.key,
              socket: client,
              deck: jsonDecode(clientRequest)['deck']);
          Player? enemy;
          try {
            enemy = players.firstWhere((e) => e.enemy.isEmpty);
          } catch (e) {
            enemy = null;
          }
          if (enemy != null) {
            player.enemy = enemy.player;
            enemy.enemy = player.player;
            player.sendNewState();
          }
          players.add(player);
        } catch (e) {
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
