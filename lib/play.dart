import 'dart:isolate';
import 'dart:convert';
import 'dart:io';

// void play(Map user, Map card) async {
//   final file = File("lib/games.json");
//   Map games = jsonDecode(file.readAsStringSync());
//   final rep = await gameEval(card["func"], user["name"], games[user["game"]]);
//   games[user["game"]] = rep;
//   file.writeAsStringSync(jsonEncode(games));
// }

Future<dynamic> gameEval(String string, String player, Map game) async {
  final uri = Uri.dataFromString(
    '''
    import 'dart:isolate';
    ${File("lib/effects.dart").readAsStringSync()}

    void main(_, SendPort port) {
      game = ${jsonEncode(game)};
      player = "$player";
      $string;
      port.send(game);
    }
    ''',
    mimeType: 'application/dart',
  );
  final port = ReceivePort();
  final isolate = await Isolate.spawnUri(uri, [], port.sendPort);
  final response = await port.firstWhere((e) => e != null);
  port.close();
  isolate.kill();
  return response;
}
