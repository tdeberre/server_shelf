import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'game.dart';

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
        final clientRequest = String.fromCharCodes(data);
        print(clientRequest);
        try {
          print(jsonDecode(clientRequest)["name"]);
          Player player = Player(
              player: jsonDecode(clientRequest)["name"],
              socket: client,
              deck: jsonDecode(clientRequest)['deck'].cast<String>());
          if (_pending == null) {
            _pending = player;
            print("${_pending?.player} pending");
          } else {
            _pending!.enemy = player.player;
            player.enemy = _pending!.player;
            players.addAll([player, _pending!]);
            _pending!.sendNewState();
            _pending = null;
            player.sendNewState();
          }
        } catch (e) {}

        if (clientRequest == "draw") {
          Player thisPlayer = players.firstWhere(
            (player) => player.socket == client,
          );
          thisPlayer.draw();
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

  /// clientCreds look like {"name" : name , "pwd" : password}
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
