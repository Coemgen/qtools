import 'dart:async' show runZoned;
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' show join, dirname;
import 'package:q_tools/model.dart';
import 'package:q_tools/persistence.dart';
import 'package:q_tools/serializers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors/shelf_cors.dart';
import 'package:shelf_route/shelf_route.dart';
import 'package:shelf_static/shelf_static.dart';

const baseDir = 'db';

main(List<String> args) async {
  var projectRoot = join(dirname(Platform.script.toFilePath()), '..');
  var webDir = join(projectRoot, 'build/web');
  var dataDir = join(projectRoot, 'data');
  var debug = (args.isNotEmpty);

  var serverConfig =
      new PersistentObject<ServerConfig>('config/${debug ? 'debug' : 'production'}.json', serverConfigSerializer);
  var users = new PersistentEntityCollection<User>('config/users.json', userSerializer);

  var story = new PersistentMap<List>('$dataDir/story.json');

  var staticHandler = createStaticHandler(webDir, defaultDocument: 'index.html');
  var dataHandler = createStaticHandler(dataDir);

  var routes = router(middleware: logRequests())
    // POST /link/create (url) => result(Link)
//    ..post('/link/create', (Request request) async {
//      var url = await request.readAsString();
//      try {
//        var document = await getDom(url);
//        var item = getItem(document, url, selectors);
//
//        return new Response.ok(JSON.encode(item));
//
//      } on IgnoreException catch (e) {
//
//        return new Response.notFound('could not parse\t$e');
//      }
//    })
    // POST /post/$id/items (items) => result(ok)
    ..get('/story', (Request request) => new Response.ok(JSON.encode(story)))
    ..post('/story', (Request request) async {
      var id = getPathParameter(request, 'name');
      var rawData = await request.readAsString();
      try {
        var json = JSON.decode(rawData);
        var accessCode = json['accessCode'];
        var user = users.firstWhere((u) => u.password == accessCode, orElse: () => null);
        if (user == null) return new Response.forbidden('');

        var edits = json['edits'] as Map<String, List>;
        story.addAll(edits);

        print('[${new DateTime.now()}] (${user.name}) stories for ${edits.keys}');
        return new Response.ok('');
      } catch (e) {
        stderr.writeln(e);
        return new Response.internalServerError();
      }
    });

  var cascade = new Cascade().add(staticHandler).add(dataHandler).add(routes.handler);

  var handler = const Pipeline()
      .addMiddleware(createCorsHeadersMiddleware(corsHeaders: {
        'Access-Control-Allow-Origin': serverConfig.entity.webClientUrl.toString(),
        'Access-Control-Allow-Headers': 'Content-Type',
        'server': 'anonymous',
      }))
      .addMiddleware(cacheControl())
      .addHandler(cascade.handler);

  var port = int.parse(Platform.environment['PORT'] ?? '8080', onError: (s) => 9999);

  runZoned(() async {
//    var host = debug ? 'localhost' :
    var server = await io.serve(handler, '0.0.0.0', port);
    print("Serving $webDir on port $port");
    printRoutes(routes);
    server.autoCompress = true;
  });
}

Middleware cacheControl() {
  return createMiddleware(responseHandler: (Response response) {
    if (!(response.headers['cache']?.startsWith('image') ?? false)) {
      return response;
    }
    return response.change(headers: {HttpHeaders.CACHE_CONTROL: 'max-age=31536000'});
  });
}

Handler middleware(Handler innerHandler) {
  return (Request request) async {
    if (request.mimeType.startsWith('image')) {
      request.change(headers: {'cache': 'true'});
    }
    return innerHandler(request);
  };
}
