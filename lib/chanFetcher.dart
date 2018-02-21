import 'dart:async';
import 'dart:convert';

import 'dart:io';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:q_tools/persistence.dart';

Future<Object> getJson(String url) async {
  var content = (await http.get(url)).body;
  try {
    return JSON.decode(content);
  } catch (e) {
    return [];
  }
}

Future<Document> getDom(String url) async {
  var content = await http.get(url);
  return parse(content.body);
}

List simplify4chanPosts(List posts) {

  var newPosts = [];
  for (var post in posts) {
    var newPost = {
      'id': post['num'],
      'timestamp': post['timestamp'],
      'timestampDeletion': post['timestamp_expired'] != '0' ? post['timestamp_expired'] : int.parse(post['timestamp_expired']),
      'title': post['title'],
      'name': post['name'],
      'trip': post['trip'],
      'email': post['email'],
      'text': post['comment'],
      'images': post['media'] == null ? [] : [{
        'url': post['media']['media_link']
      }]
    };
    newPosts.add(newPost);
  }
  return newPosts;
}

toNew(Map post) {
  return {
    'id': post['num'],
    'timestamp': post['timestamp'],
    'timestampDeletion': post['timestamp_expired'] != '0' ? post['timestamp_expired'] : post['timestamp_expired'],
    'userId': post['poster_hash'],
    'threadId': post['thread_num'],
    'title': post['title'],
    'name': post['name'],
    'trip': post['trip'],
    'email': post['email_processed'],
    'text': post['comment'],
    'images': post['media'] == null ? [] : [{
      'url': post['media']['media_link']
    }],
    'source': '4chan_pol',
    'link': 'https://archive.4plebs.org/pol/thread/${post['thread_num']}/#${post['num']}',
  };
}

Future<List<Map>> get8ChanPostsUsingDom(String board, int id) async {
  var linkMatch = new RegExp(r'>>(\d+)', multiLine: true);

  threadUrl(int id) => 'https://8ch.net/$board/res/$id.html';

  var result = await getDom(threadUrl(id));

  var toPost = makeChanPostToPost(board, id);
  var threadPosts = result.querySelectorAll('.post').map(toPost).toList();

  for (var newPost in threadPosts) {
    if (linkMatch.hasMatch(newPost['text'])) {
      var referenceIds = linkMatch.allMatches(newPost['text']).map((p) => p.group(1));
      var referencePosts = referenceIds
          .map((id) => threadPosts.firstWhere((p) => p['id'] == id, orElse: () => null))
          .where((p) => p != null)
          .toList();
      if (referencePosts.isNotEmpty) newPost['references'] = referencePosts;
//      if (referenceIds.isNotEmpty) newPost['referenceIds'] = referenceIds;
    }
  }
  return threadPosts;
}

Function makeChanPostToPost(String board, int threadId) {
  return (Element post) {
    return {
      'id': post.id.split('_')[1],
      'userId': post.querySelector('.poster_id')?.text?.trim(),
      'timestamp': int.parse(post.querySelector('time').attributes['unixtime']),
      'subject': post.querySelector('.subject')?.text?.trim(),
      'name': post.querySelector('.name')?.text?.trim(),
      'email': post.querySelector('.email')?.text?.trim(),
      'trip': post.querySelector('.trip')?.text?.trim(),
      'text': cleanHtmlText(post.querySelector('.body').innerHtml),
      'images': post
          .querySelectorAll('.files>.file')
          .where((e) => e.querySelector('.fileinfo') != null)
          .map((e) => {
                'url': e.querySelector('.fileinfo a').attributes['href'],
                'filename': e.querySelector('.postfilename')?.text,
              })
          .toList(),
      'threadId': threadId.toString(),
      'source': '8chan_$board',
      'link': 'https://8ch.net/${post.querySelector('a.post_no').attributes['href']}',
    };
  };
}

Future<String> downloadImage(String url, String outputDir) async {
  var response = await http.get(url);
  var baseName = Uri.parse(url).pathSegments.last;
  new File('$outputDir/$baseName').writeAsBytesSync(response.bodyBytes);
  return baseName;
}

//abstract class IdObject {
//  String get id;
//
//  operator ==(Object other) => other is IdObject && id == other.id;
//
//  get hashCode => super.hashCode;
//}
//
//class Post extends IdObject {
//  @override
//  final String id;
//  final String userId;
//  final int timestamp;
//  final String subject;
//  final String name;
//  final String email;
//  final String trip;
//  final String text;
//  final List<Image> images;
//  final String threadId;
//  final String source;
//  final String link;
//
//  Post(this.id, this.userId, this.timestamp, this.subject, this.name, this.email, this.trip, this.text, this.images, this.threadId, this.source, this.link);
//  Map toJson() => {'id': id, 'userId': userId, 'timestamp': timestamp, ''};
//}
cleanHtmlText(String htmlText) {
  var emptyPattern = new RegExp(r'<p class="body-line empty "></p>');
  var referencePattern = new RegExp(r'<a [^>]+>&gt;&gt;(\d+)</a>');
  var linkPattern = new RegExp(r'<a [^>]+>(.+?)</a>');
  var quotePattern = new RegExp(r'<p class="body-line ltr quote">&gt;(.+?)</p>');
  var paragraphPattern = new RegExp(r'<p class="body-line ltr ">(.+?)</p>');

  return htmlText
      .replaceAll(emptyPattern, '\n')
      .replaceAllMapped(referencePattern, (m) => '>>${m.group(1)}')
      .replaceAllMapped(linkPattern, (m) => '${m.group(1)}')
      .replaceAllMapped(quotePattern, (m) => '>${m.group(1)}\n')
      .replaceAllMapped(paragraphPattern, (m) => '${m.group(1)}\n');
}