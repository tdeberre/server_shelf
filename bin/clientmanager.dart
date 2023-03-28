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
      print("client?");
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
              .firstWhere((e) => e.value["token"] == clientRequest["token"])
              .key;
          Player player = Player(
              player: token,
              socket: client,
              deck: jsonDecode(clientRequest)['deck']);
          Player? enemy;
          try {
            enemy = players.firstWhere((e) => e.enemy.isEmpty);

            print("enemy found"); //
          } catch (e) {
            print("no enemy found"); //
            enemy = null;
          }
          if (enemy != null) {
            player.enemy = enemy.player;
            enemy.enemy = player.player;
            print("sending state"); //
            player.sendNewState();
          }
          players.add(player);
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
