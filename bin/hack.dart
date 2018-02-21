import 'dart:convert';
import 'package:q_tools/chanFetcher.dart';

main(List<String> args) async {
  if (args.length != 1) {
    print('usage: PATH_TO_QCodefag.github.io');
    return;
  }
  var sinkDir = args[0] + '/data';

  var board = 'qresearch';
  var threadId = 381169;

  var allNewPosts = await get8ChanPostsUsingDom(board, threadId);

  var ids = ['382122'];
  var newPosts = allNewPosts.where((p) => ids.contains(p['id'])).toList();
  print(JSON.encode(newPosts));

  var imageUrls = (newPosts
      .where((p) => p.containsKey('references'))
      .map((p) => p['references'])
      .fold([], (p, List c) => p..addAll(c))
    ..addAll(newPosts)).fold([], (p, c) => p..addAll(c['images'])).map((i) => i['url']);

  for (var imageUrl in imageUrls) {
    await downloadImage(imageUrl, '$sinkDir/images');
  }
}