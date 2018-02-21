import 'dart:async';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:q_tools/chanFetcher.dart';
import 'package:q_tools/persistence.dart';
import 'package:q_tools/renderer.dart';
import 'package:q_tools/serializers.dart';

final Logger log = new Logger('main');

main(List<String> args) async {
  var projectRoot = absolute(join(dirname(Platform.script.toFilePath()), '..'));
  var webDir = join(projectRoot, 'web');

  initLogger();
  log.fine('looking for new posts');

  var posts = new PersistentList('data/posts.json');

  var result1 = await updateDataRepository('greatawakening', posts, webDir);

  var result2 = await updateDataRepository('qresearch', posts, webDir);

  if (result1 != null || result2 != null) {
    posts.save();
    var indexDocument = buildIndexHtml(projectRoot);
    var file = new File(join(projectRoot, 'web/index.html'));
    file.writeAsStringSync(indexDocument.outerHtml);

    updateAmazonSiteFile('index.html', projectRoot, webDir);
    var newImageNames = [];
    if (result1 != null) {
      newImageNames.addAll(result1);
    }
    if (result2 != null) {
      newImageNames.addAll(result2);
    }
    for (var imageName in newImageNames) {
      updateAmazonSiteFile('images/$imageName', projectRoot, webDir, 31536000);
    }
  }
}

updateAmazonSiteFile(String fileName, String projectDir, String sinkDir, [int cacheControl]) {
  Process.runSync(
      join(projectDir, 'deploy.sh'), [fileName, cacheControl == null ? '' : '--cache-control $cacheControl'],
      workingDirectory: sinkDir);
}

Document buildIndexHtml(String projectRoot) {
  var document = parse(new File(join(projectRoot, 'data/index2.html')).readAsStringSync());
  var legend = new PersistentMap<String>(join(projectRoot, 'data/legend.json'));
  var items = new PersistentEntityCollection(join(projectRoot, 'data/posts.json'), postSerializer).toList();

  items.sort((a, b) => a.date.compareTo(b.date));

  render(document, items, legend);

  return document;
}

Future<List<String>> updateDataRepository(String board, List posts, String webDir) async {
  var newPosts = await findNewQPosts(board, posts.map((p) => p['id']).toList());
  if (newPosts.isNotEmpty) {
    posts.addAll(newPosts);

    var fileNames = [];
    var imageUrls = (newPosts
        .where((p) => p.containsKey('references'))
        .map((p) => p['references'])
        .fold([], (p, List c) => p..addAll(c))
          ..addAll(newPosts)).fold([], (p, c) => p..addAll(c['images'])).map((i) => i['url']);

    for (var imageUrl in imageUrls) {
      var fileName = await downloadImage(imageUrl, join(webDir, 'images'));
      fileNames.add(fileName);
    }

    log.info('found ${newPosts.length} new posts on $board');
    return fileNames;
  }
  return null;
}

Future<List> findNewQPosts(String board, List<String> existingPostIds) async {
  const trips = const ['!UW.yye1fxo'];

  var catalogUrl = 'https://8ch.net/$board/catalog.json';

  var threads = ((await getJson(catalogUrl)) as List<Map>).fold([], (p, e) => p..addAll(e['threads'] ?? [])) as List;

  var threadIds = threads.take(30).map((p) => p['no']).toList();

  var result = [];
  for (var threadId in threadIds) {
    var allNewPosts = await get8ChanPostsUsingDom(board, threadId);

    var newPosts = allNewPosts.where((p) => trips.contains(p['trip']) && !existingPostIds.contains(p['id'])).toList();

    result.addAll(newPosts);
  }
  return result;
}

initLogger() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}:${rec.time}:${rec.message}');
  });
}
