import 'dart:io';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

String _getDataFrom(String fileName) {
  return File("bin/data/$fileName").readAsStringSync();
}

final _router = Router()
  ..get("/cards", _cardsHandler)
  ..get("/decks/<user>", _decksFromUserHandler)
  ..post("/decks/<user>", _decksToUserHandler)
  ..get("/test", _test)
  ..get("/close", _closeHandler);

Response _test(req) {
  return Response.ok("ok");
}

Response _closeHandler(req) {
  exit(0);
  //ignore:dead_code
  return Response.ok("closed");
}

Response _cardsHandler(Request req) {
  final data = _getDataFrom("cards.json");
  Map<String, dynamic> map = jsonDecode(data);
  map.forEach((k, v) => v.remove("func"));
  final rep = jsonEncode(map);
  return Response.ok(rep);
}

Response _decksFromUserHandler(Request req, String user) {
  final data = _getDataFrom("decks.json");
  final map = jsonDecode(data)[user];
  final rep = jsonEncode(map);
  return Response.ok(rep);
}

Future<Response> _decksToUserHandler(Request req, String user) async {
  final body = await req.readAsString();
  if (body.isEmpty) {
    return Response.forbidden("body is empty");
  }
  final data = _getDataFrom("decks.json");
  Map<String, dynamic> map = jsonDecode(data);
  if (!map.keys.contains(user)) {
    return Response.forbidden("user not found");
  }
  map[user]!.addAll(jsonDecode(body));
  File("bin/data/decks.json").writeAsStringSync(jsonEncode(map));
  return Response(201);
}

class Api {
  static void init() async {
    final ip = InternetAddress.anyIPv4;
    final port = int.parse(Platform.environment['PORT'] ?? '56561');
    final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);
    final server = await serve(handler, ip, port);
    print('API listening on port ${server.port}');
  }
}
