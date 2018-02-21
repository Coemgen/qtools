import 'dart:io';

import 'package:html/parser.dart';
import 'package:q_tools/renderer.dart';
import 'package:q_tools/serializers.dart';
import 'package:q_tools/persistence.dart';

main() {
  var document = parse(new File('data/index2.html').readAsStringSync());
  var legend = new PersistentMap<String>('data/legend.json');
  var items = new PersistentEntityCollection('data/posts.json', postSerializer).toList();

  items.sort((a, b) => a.date.compareTo(b.date));

  render(document, items, legend);

  new File('web/index.html').writeAsStringSync(document.outerHtml);
}