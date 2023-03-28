import 'dart:io';

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
  ..get("/site/<page>", _homeHandler)
  ..get("/<page>", _notFoundHandler);

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
