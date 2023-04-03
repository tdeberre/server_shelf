import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'game.dart';
import 'mailer.dart';

class Api {
  static void init() async {
    _tokenCleaner();
    final ip = InternetAddress.anyIPv4;
    final port = int.parse(Platform.environment['PORT'] ?? '56561');
    final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);
    final server = await serve(handler, ip, port);
    print('API listening on port ${server.port}');
  }
}

String _getDataFrom(String fileName) =>
    File("bin/data/$fileName").readAsStringSync();

String _getRandString(int len) {
  var random = Random.secure();
  var values = List<int>.generate(len, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

final _router = Router()
  //get
  ..get("/api/cards", _cardsHandler)
  ..get("/api/decks/<user>", _decksFromUserHandler)
  //post
  ..post("/api/token", _tokenHandler)
  ..post("/api/register", _registerHandler)
  ..post("/api/validate", _validateHandler)
  ..post("/api/decks/<user>", _decksToUserHandler) //TODO
  ..post("/api/draw", _drawHandler)
  ..post("/api/play/<card>", _playHandler)
  //debug
  ..get("/api/test", _test)
  ..get("/api/close", _closeHandler);

//get
Response _cardsHandler(Request req) {
  final data = _getDataFrom("cards.json");
  Map<String, dynamic> map = jsonDecode(data);
  map.forEach((k, v) => v.remove("func"));
  final rep = jsonEncode(map);
  return Response.ok(rep);
}

Response _decksFromUserHandler(Request req, String user) {
  final data = _getDataFrom("decks.json");
  final map = jsonDecode(data);
  final rep = jsonEncode(map[user]);
  return Response.ok(rep);
}

//post
Future<Response> _tokenHandler(Request req) async {
  final creds;
  try {
    creds = jsonDecode(await req.readAsString());
  } catch (e) {
    return Response.badRequest(body: "Server can't read data");
  }
  final user = jsonDecode(_getDataFrom("users.json"))[creds["email"]];
  if (user.toString() == creds.toString()) {
    final token = _getRandString(255);
    tokens.addAll({
      creds["email"]: {
        "token": token,
        "expiration": DateTime.now().add(Duration(minutes: 15)),
      }
    });
    return Response(201, body: jsonEncode(token));
  }
  return Response.unauthorized("Wrong credentials");
}

Map<String, dynamic> tokens = {};

void _tokenCleaner() async {
  Timer.periodic(Duration(minutes: 15), (timer) {
    tokens.removeWhere(
        (key, value) => value["expiration"].isBefore(DateTime.now()));
  });
}

Future<Response> _registerHandler(req) async {
  final body = await req.readAsString();
  final pending = File("bin/data/pending.json");
  Map requestMap = jsonDecode(body);
  Map pendingMap = jsonDecode(pending.readAsStringSync());
  final key = _getRandString(255);
  pending.writeAsString(jsonEncode({
    ...pendingMap,
    ...{
      requestMap["email"]: {
        ...requestMap,
        ...{"key": key}
      }
    }
  }));
  sendMail("deberretheo@gmail.com", key);
  return Response(201, body: "ok");
}

Future<Response> _validateHandler(req) async {
  final body = await req.readAsString();
  final pending = File("bin/data/pending.json");
  final requestMap = jsonDecode(body);
  Map pendingMap = jsonDecode(pending.readAsStringSync());
  final user = requestMap.entries.first.key;
  final key = requestMap.entries.first.value;

  Map<String, dynamic> validatedUser = pendingMap[user];
  if (validatedUser["key"] == key) {
    validatedUser.remove("key");
    final users = File("bin/data/users.json");
    Map usersMap = jsonDecode(users.readAsStringSync());
    usersMap.addAll(validatedUser);
    users.writeAsStringSync(jsonEncode(usersMap));
    pendingMap.remove(validatedUser["email"]);
    pending
        .writeAsStringSync(pendingMap.isEmpty ? "{}" : jsonEncode(pendingMap));
  } else {
    return Response.badRequest(body: "cant validate");
  }
  return Response(201, body: "ok");
}

Future<Response> _decksToUserHandler(Request req, String user) async {
  final body = await req.readAsString();
  final data = _getDataFrom("decks.json");
  Map<String, dynamic> map = jsonDecode(data);
  if (body.isEmpty) {
    return Response.badRequest(body: "body is empty");
  }
  if (!map.keys.contains(user)) {
    return Response.forbidden("user not found");
  } else {
    map[user].addAll(jsonDecode(body));
    File("bin/data/decks.json").writeAsStringSync(jsonEncode(map));
    return Response(201);
  }
}

Future<Response> _drawHandler(Request req, String card) async {
  final body = await req.readAsString();
  if (body.isEmpty) {
    return Response.badRequest(body: "body is empty");
  }
  if (jsonDecode(body).contain("token") == false) {
    return Response.badRequest(body: "token not provided");
  }
  final token = jsonDecode(body)["token"];
  final user = tokens.entries
      .where((e) => (e.value["token"] == token &&
          e.value["expiration"].isAfter(DateTime.now())))
      .first
      .key;
  final player = players.firstWhere((e) => e.player == user);
  player.draw();
  return Response(201);
}

Future<Response> _playHandler(req, String card) async {
  final body = await req.readAsString();
  if (body.isEmpty) {
    return Response.badRequest(body: "body is empty");
  }
  final token = jsonDecode(body)["token"];
  final user = tokens.entries.where((e) => (e.value["token"] == token &&
      e.value["expiration"].isAfter(DateTime.now())));
  if (user.isEmpty) {
    return Response.forbidden('auth error');
  }
  final player = players.firstWhere((e) => e.player == user.first.key);
  player.play(card);
  return Response(201);
}

//debug
Response _test(Request req) {
  return Response.ok("ok");
}

Response _closeHandler(req) {
  exit(0);
  //ignore:dead_code
  return Response.ok("closed");
}
