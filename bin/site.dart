import 'dart:io';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

class Site {
  static void init() async {
    final ip = InternetAddress.anyIPv4;
    final port = int.parse(Platform.environment['PORT'] ?? '80');
    final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);
    final server = await serve(handler, ip, port);
    print('Site listening on port ${server.port}');
  }
}

getTemplate(String name) {
  return File("bin/template/$name.html").readAsStringSync();
}

final _router = Router()
  ..get("/site/private/<page>", _notFoundHandler)
  ..get("/site/<page>", _homeHandler)
  ..get("/site/validate/<user>/<key>", _validateHandler);

Response _homeHandler(Request req, String name) {
  try {
    String page = getTemplate(req.params["page"].toString());
    return Response.ok(page, headers: {"Content-Type": "text/html"});
  } catch (e) {
    return _notFoundHandler(req);
  }
}

Response _notFoundHandler(req) {
  return Response.notFound(getTemplate("page_not_found"),
      headers: {"Content-Type": "text/html"});
}

Response _validateHandler(Request req, String user, String key) {
  final pending = File("bin/data/pending.json");
  Map pendingMap = jsonDecode(pending.readAsStringSync());

  if (pendingMap.isEmpty) {
    return Response.badRequest(body: "no pending signup");
  }
  Map<String, dynamic> validatedUser = pendingMap[user];

  if (validatedUser["key"] == key) {
    validatedUser.remove("key");
  } else {
    return Response.badRequest(body: "cant validate");
  }

  //add user to db
  final users = File("bin/data/users.json");
  Map<String, dynamic> usersMap = jsonDecode(users.readAsStringSync());
  usersMap.addAll(<String, dynamic>{"$user": validatedUser});
  users.writeAsStringSync(jsonEncode(usersMap));
  //remove from pending
  pendingMap.remove(user);
  pending.writeAsStringSync(pendingMap.isEmpty ? "{}" : jsonEncode(pendingMap));

  return Response(200,
      body: File("bin/template/private/validated.html").readAsStringSync(),
      headers: {"Content-Type": "text/html"});
}
