import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

import 'package:q_tools/chanFetcher.dart';
import 'package:q_tools/persistence.dart';

main() async {

  const baseDir = 'web/data/news';
//  var posts = new ManagedJsonList<Map>('$baseDir/posts.json');
  var ignoreUrls = new PersistentSet<String>('$baseDir/ignore.json');
//  var ignoreThreadIds = new ManagedJsonList<int>('$baseDir/ignore-threadIds.json');
//  var newPosts = await get8ChanPosts('cbts', ignorePostIds: posts.map((p) => p['postId']).toList());

  var threadIds = new PersistentSet<int>('$baseDir/threadIds.json');
  var alreadyParsedThreadIds = new PersistentSet<int>('$baseDir/threadIds_ignore.json');
  var urls = new PersistentSet<String>('$baseDir/urls.json');
  var fail = new PersistentSet<String>('$baseDir/fail.json');

  for(var threadId in threadIds.where((id) => !alreadyParsedThreadIds.contains(id))) {

    var newPosts = await get8ChanPostsUsingDom('cbts', threadId);

    var newUrls = newPosts
        .map((p) => p['text'])
        .join('\n')
        .split('\n')
        .where((line) => line.startsWith('http') || line.startsWith(new RegExp(r'\w+\.\w{2-3}')))
        .map((p) {
          p = p.replaceAll(' ', '');
          if(!p.startsWith('http'))
            p = 'http://$p';
          return p;
        })
        .where((u) => !urls.contains(u))
        .toList();

    var unpackedArchiveUrls = new PersistentSet<String>('$baseDir/unpackedArchiveUrls.json');

    for (var url in newUrls) {
      try {
        if(url.contains(new RegExp(r'archive\.(is|org|fo)'))) {
          // archive urls
          var content = await http.get(url);
          var document = parse(content.body);

          var newUrl = document.querySelector('[name=q],[name=url]').attributes['value'];
          if (ignoreUrls.contains(newUrl)) continue;
          urls.add(newUrl);
          unpackedArchiveUrls.add(url);
        } else {
          urls.add(url);
        }
      } catch (e) {
        fail.add(url);
      }
    }
    print('added ${newUrls.length} urls from $threadId');
    alreadyParsedThreadIds.add(threadId);
  }
}