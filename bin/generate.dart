import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:q_tools/chanFetcher.dart';
import 'package:q_tools/persistence.dart';

const dataDir = 'web/data';

main() {

}

get8ChanPosts() async {
  const trips = const [
//    '!ITPb.qbhqo',
    '!UW.yye1fxo'
  ];
  const userIds = const ['7681cc', 'ac1ea3', '500f84', '8f9964'];

  var alreadyParsedThreadIds = new PersistentSet<int>('$dataDir/qposts/threadIds_ignore.json');
  var threadIds = new PersistentSet<int>('$dataDir/qposts/threadIds.json');
//  var qPosts = new ManagedJsonList('$dataDir/qposts/8chan.json');
//  var qPosts = new ManagedJsonList('$dataDir/qposts/polTrip8chanPosts.json');
  var qPosts = new PersistentList('$dataDir/qposts/cbtsNonTrip8chanPosts.json');
  var existingIds = qPosts.map((p) => p['id']);

  var id = 238736;
//  for(var id in threadIds.where((id) => !alreadyParsedThreadIds.contains(id))) {
  var posts = await get8ChanPostsUsingDom('cbts', id);
  var newPosts = posts
      .where((p) => (trips.contains(p['trip']) || userIds.contains(p['userId'])) && !existingIds.contains(p['id']))
      .toList();
  qPosts.addAll(newPosts);
  alreadyParsedThreadIds.add(id);
//  }
  qPosts.sort((a, b) => a['timestamp'] - b['timestamp']);
  qPosts.save();
  print(qPosts.length);
}

getAnswers() {
  var content = new File('lib/src/data/tmp').readAsStringSync();
  var dividerPattern = new RegExp(r'^(\d\d/\d\d/\d\d+)?\t(?:>>)?(\d+)(?:[^\n]+)\n', multiLine: true);
  var answersPattern = new RegExp(r'([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\n', multiLine: true);
  var ids = dividerPattern.allMatches(content).map((m) => int.parse(m.group(2))).toList();
  var answerParts = content.split(dividerPattern).skip(1).toList();

  var result = {};
  for (var i = 0; i < ids.length; i++) {
    var id = ids[i];

    var lines = answersPattern
        .allMatches(answerParts[i])
        .map((m) => {
              'line': m.group(2),
              'answer': stripQuotes(m.group(3)),
              'extraAnswer': stripQuotes(m.group(4)),
              'confidence': m.group(6),
            })
        .toList();

    if (lines.map((l) => l['answer']).join('').trim().isEmpty) continue;

    var output = '';
    for (var line in lines) {
      if (line['line'].isNotEmpty) output += '### ${line['line']}\n\n';
      if (line['answer'].isNotEmpty) output += line['answer'] + '\n\n';
      if (line['extraAnswer'].isNotEmpty) output += line['extraAnswer'] + '\n\n';
    }
    result[id.toString()] = output;
  }

  new File('$dataDir/answers.js').writeAsStringSync(new JsonEncoder.withIndent('    ').convert(result));
}

stripQuotes(String text) {
  if (text.startsWith('"') && text.endsWith('"')) return text.substring(1, text.length - 1);
  return text;
}

get4ChanTripPosts() async {
  const archiveUrl = 'http://archive.4plebs.org/_/api/chan/search/?tripcode=ITPb.qbhqo&end=2017-12-15&page=';

  getPosts(int page) async {
    var result = await http.get('$archiveUrl$page');
    var json = JSON.decode(result.body);
    sleep(new Duration(seconds: 5));
    return json['0']['posts'];
  }

  var posts = [];
  for (var i = 1; i < 6; i++) {
    posts.addAll(await getPosts(i));
    print(i);
  }
  posts.sort((a, b) => a['timestamp'] - b['timestamp']);
  return posts;
}

get4ChanNonTripPosts() async {
  const userIds = const [
    'P3Lk4PKG',
    'Eka5Om1K',
    'grTMpzrL',
    'pGukiFmX',
    'zGyR4tyi',
    'KC17sSpZ',
    'WBXFv1gI',
    'GVUvg1M7',
    's4Iv8TW8',
    'AZhJ37bn',
    'v3eCc2tY',
    'L8quGPI9',
    'hHkrVD7x',
    'FAkr+Yka',
    'KKIreCTB',
    'NOjYqEdl',
    'BQ7V3bcW',
    'cS8cMPVQ',
    '8GzG+UJ9'
  ];
  var linkMatch = new RegExp(r'>>(\d+)', multiLine: true);
  const idUrl = 'http://archive.4plebs.org/_/api/chan/post/?board=pol&num=';
  const userIdUrl = 'http://archive.4plebs.org/_/api/chan/search/?uid=';

  Future<List> getPosts(String id) async {
    var result = await http.get('$userIdUrl$id');
    var json = JSON.decode(result.body);
    sleep(new Duration(seconds: (60 / 5 + 1).ceil()));
    return json['0']['posts'];
  }

  Future<Map> getPost(String id) async {
    var result = await http.get('$idUrl$id');
    var json = JSON.decode(result.body);
    return json;
  }

  var posts = new PersistentList('$dataDir/qposts/pol4chanPosts.json');
  var ids = posts.map((p) => p['id']).toList();
  for (var id in userIds) {
    var chanPosts = await getPosts(id);
    var newPosts = chanPosts.map(toNew).where((p) => !ids.contains(p['id'])).toList();
    for (var newPost in newPosts) {
      if (newPost['text'] != null && linkMatch.hasMatch(newPost['text'])) {
        var referenceIds = linkMatch.allMatches(newPost['text']).map((p) => p.group(1));
        var referenceChanPosts = await Future.wait(referenceIds.map(getPost));
        var referencePosts = referenceChanPosts.map(toNew).toList();
        if (referencePosts.isNotEmpty) newPost['references'] = referencePosts;
      }
    }
    posts.addAll(newPosts);
    print(newPosts);
  }

  const tripUrl = 'http://archive.4plebs.org/_/api/chan/search/?tripcode=ITPb.qbhqo&end=2017-12-15&page=';

  getTripPosts(int page) async {
    var result = await http.get('$tripUrl$page');
    var json = JSON.decode(result.body);
    sleep(new Duration(seconds: 5));
    return json['0']['posts'];
  }

  for (var i = 1; i < 6; i++) {
    var chanPosts = await getTripPosts(i);
    var newPosts = chanPosts.map(toNew).where((p) => !ids.contains(p['id'])).toList();
    for (var newPost in newPosts) {
      if (newPost['text'] != null && linkMatch.hasMatch(newPost['text'])) {
        var referenceIds = linkMatch.allMatches(newPost['text']).map((p) => p.group(1));
        var referenceChanPosts = await Future.wait(referenceIds.map(getPost));
        var referencePosts = referenceChanPosts.map(toNew).toList();
        if (referencePosts.isNotEmpty) newPost['references'] = referencePosts;
      }
    }
    posts.addAll(newPosts);
    print(newPosts);
  }

  posts.sort((a, b) => a['timestamp'] - b['timestamp']);
  posts.save();
}
