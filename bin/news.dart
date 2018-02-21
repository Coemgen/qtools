import 'package:q_tools/chanFetcher.dart';
import 'package:q_tools/persistence.dart';
import 'package:q_tools/snippetBuilder.dart';

const baseDir = 'web/data/news';
bool postpone = true;
main() async {
  scrapeNews();
}

scrapeNews() async {

  var result = new PersistentList<Map<String, dynamic>>('$baseDir/news.json');
  var success = result.map((item) => item['url']).toList();
  var selectors = new PersistentMap<String>('$baseDir/selectors.json');
  var ignore = new PersistentSet<String>('$baseDir/ignore.json');
  var urls = new PersistentSet<String>('$baseDir/urls.json');
  var blacklist = new PersistentSet<String>('$baseDir/blacklist.json');
  var fail = [];

  for (var url in urls) {
    if (success.contains(url) || blacklist.contains(Uri.parse(url).host) || ignore.contains(url)) continue;
    print(url);

    try {
      var document = await getDom(url);

      var item = getItem(document, url, selectors);

      result.add(item);
      success.add(url);
    } on IgnoreException catch (e) {
      ignore.add(e.message);
    } on Exception catch (e) {
      fail.add(url);
    }
  }
  print('${urls.length - fail.length} / ${urls.length}');
  print('failed\n$fail');
}

scrapeUrls() async {
  var threadIds = new PersistentSet<int>('$baseDir/threadIds.json');
  var urls = new PersistentSet<String>('$baseDir/urls.json');

  for(var threadId in threadIds) {
    var posts = await get8ChanPostsUsingDom('cbts', threadId);
    var newUrls = posts
        .map((p) => (p['text'] as String)
        .split('\n')
        .where((s) => s.startsWith('http'))
        .map((s) => s.replaceAll(' ', ''))
        .fold([], (p, c) => p..add(c))
        .toList()
    );
    urls.addAll(newUrls);
  }
}
