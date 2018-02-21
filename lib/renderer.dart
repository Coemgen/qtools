import 'package:html/dom.dart';
import 'package:q_tools/model.dart';

void render(Document document, List<Post> items, Map<String, String> legend) {
  var container = document.querySelector('main');
  var lastDate = getDate(items.last.date, EST);
  var subContainer = new Element.tag('section');
  container.append(build.date(lastDate));

  var i = items.length;
  for (var item in items.reversed) {
    var date = getDate(item.date, EST);
    if (lastDate.isAfter(date)) {
      lastDate = date;
      container.append(subContainer);
      container.append(build.date(date));
      subContainer = new Element.tag('section');
    }
    subContainer.append(build.postWithReplies(item, i--, legend));
  }
  container.append(subContainer);
}

DateTime getDate(DateTime date, [Duration timezone]) {
  var d = timezone != null ? date.add(timezone) : date;
  return new DateTime.utc(d.year, d.month, d.day);
}

var build = new ElementBuilder();

class ElementBuilder {
  Element tag(String name, {Map<String, String> attributes, Iterable<Node> children, Node child, String text}) {
    var element = new Element.tag(name);
    if (children != null && child != null && text != null)
      throw new Exception('Can only have one of `children`, `child`, `text`');
    if (attributes != null) element.attributes.addAll(attributes);
    children?.forEach(element.append);
    if (child != null) element.append(child);
    if (text != null) element.text = text;
    return element;
  }

  Element date(DateTime date) {
    return tag('h3',
        attributes: {
          'class': 'center sticky',
        },
        child: tag('time', attributes: {'datetime': date.toIso8601String()}, text: formatDate(date)));
  }

  Element img(Image image) {
    var localUrl = '/images/' + image.url.pathSegments.last.toString();
    return tag('a', attributes: {
      'href': localUrl,
      'target': '_blank',
    }, children: [
      tag('span',
          attributes: {
            'class': 'filename',
            'title': 'file name',
          },
          text: image.filename),
      tag('img', attributes: {
        'class': 'contain lazyload',
        'data-src': localUrl,
        'width': '300',
        'height': '300',
      })
    ]);
  }

  Element postWithReplies(Post item, int index, Map<String, String> legend) {
    return tag('article',
        attributes: {
          'class': 'source_${item.source}${item.deletedDate != null ? 'deleted' : ''}',
        },
        children: [
          tag('span', attributes: {'class': 'counter'}, text: index.toString()),
        ]
          ..addAll(item.references?.map((r) => tag('blockquote', child: post(r, legend))) ?? [])
          ..add(tag('div', attributes: {'id': 'post_${item.source}_${item.id}'}, child: post(item, legend))));
  }

  Element post(Post item, Map<String, String> legend) {
    return tag('div', children: [
      tag('header', children: [
        tag('time',
            attributes: {'title': 'EST (UTC -05:00', 'datetime': item.date.toIso8601String()},
            text: '${formatDate(item.date, EST)} ${formatTime(item.date, EST)}'),
        tag('span', attributes: {'class': 'subject', 'title': 'subject'}, text: item.subject),
        tag('span', attributes: {'class': 'trip', 'title': 'trip'}, text: item.trip),
        tag('span', attributes: {'class': 'name', 'title': 'name'}, text: item.name),
        tag('span', attributes: {'class': 'email', 'title': 'email'}, text: item.email),
        tag('span', attributes: {'class': 'userid', 'title': 'userid'}, text: item.userId),
        tag('a', attributes: {'href': item.link, 'target': '_blank'}, text: item.id),
      ]),
      tag('div', children: item.images?.map(img)),
      formattedText(item.text, legend),
    ]);
  }

  final quotePattern = new RegExp(r'(^>[^>].*\n?)+', multiLine: true);
  final urlPattern = new RegExp(r'(https?://[.\w/?\-=&#]+)', multiLine: true);
  final bracketPattern = new RegExp(r'(\[[^[]+])', multiLine: true);

  Element formattedText(String text, Map<String, String> legend) {
    var legendPattern = new RegExp(r'([^a-zA-Z_])(' + legend.keys.join('|') + r')([^a-zA-Z_])', multiLine: true);
    if (text == null) return new Element.html('<div class="text"></div>');
    var formatted = text
        .replaceAllMapped(quotePattern, (match) => '<q>${match.group(1)}</q>')
        .replaceAllMapped(urlPattern, (match) => '<a href="${match.group(1)}" target="_blank">${match.group(1)}</a>')
        .replaceAllMapped(bracketPattern, (match) => '<strong>${match.group(1)}</strong>')
        .replaceAllMapped(
            legendPattern,
            (match) => '${match.group(1)}<abbr title="${legend[match.group(2)]}">${match.group(
            2)}</abbr>${match.group(3)}');
    return new Element.html('<div class="text">$formatted</div>');
  }
}

const months = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

xx(int x) => x < 10 ? '0$x' : '$x';

String formatDate(DateTime date, [Duration timezone]) {
  var d = timezone != null ? date.add(timezone) : date;
  return '${months[d.month - 1]} ${d.day} ${d.year}';
}

String formatTime(DateTime date, [Duration timezone]) {
  var d = timezone != null ? date.add(timezone) : date;
  return '${xx(d.hour)}:${xx(d.minute)}:${xx(d.second)}';
}

const EST = const Duration(hours: -5);
