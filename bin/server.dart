import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:kleiderbazar/websockethandler.dart';
import 'package:path/path.dart' as p;

// Configure routes.
// ignore: unused_element
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler);

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

String getMimeType(File f) {
  switch (p.extension(f.path)) {
    case '.html':
      return 'text/html';
    case '.css':
      return 'text/css';
    case '.js':
      return 'text/javascript';
    case '.png':
      return 'image/png';
    case '.jpg':
      return 'image/jpeg';
    case '.svg':
      return 'image/svg+xml';
    case '.pdf':
      return 'application/pdf';
  }
  return 'text/plain';
}

Future<Response> _echoHandler(Request request) async {
  var path = request.url.path;
  if (path == 'ws') {
    return await webSocketHandler(onConnect,
        pingInterval: Duration(seconds: 45))(request);
  } else if (path == '') {
    path = 'index.html';
  }

  File f = File('web/$path');
  if (!await f.exists()) {
    return Response.notFound('Requested resource couldn\'t be found');
  }
  return Response(200,
      body: f.openRead(), headers: {'Content-Type': getMimeType(f)});
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  Response _cors(Response response) => response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, X-Auth-Token',
      });

  var _fixCORS = createMiddleware(responseHandler: _cors);

  final _handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_fixCORS)
      .addHandler(_echoHandler);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '7070');
  final server = await serve(_handler, ip, port);
  print('Server listening on port ${server.port}');
  //print(allUsers);
}
