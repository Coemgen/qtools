import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:html/dom.dart';

Map getItem(Document document, String url, Map<String, String> selectors) {
  var result = <String, Object>{
    'id': sha256.convert(url.codeUnits).toString(),
    'url': url,
  };

  // try JSON-LD (confidence 10)
  var rawJsonLd = document
      .querySelector('[type="application/ld+json"]')
      ?.text
      ?.replaceAll("\n", "")
      ?.replaceFirst('//<![CDATA[', '')
      ?.replaceFirst('//]]>', '');
  if (rawJsonLd != null) {
    try {
      var jsonLd = JSON.decode(rawJsonLd) as Map<String, dynamic>;
      if ((jsonLd['@type'] as String).contains('Article')) {
        result['date'] = jsonLd.containsKey('datePublished')
            ? parseDate(jsonLd['datePublished'], null).millisecondsSinceEpoch
            : getPublishedDateTimestamp(document, url, selectors);
        result['headline'] = jsonLd.containsKey('headline') ? jsonLd['headline'] : jsonLd['name'];
        result['description'] = jsonLd['description'];
        var image = jsonLd['image'] ?? getImageUrl(document);
        if (image is List) image = image[0];
        result['imageUrl'] = image is String ? image : image['url'];
        return result;
      }
    } catch(e) {}
  }

  result['date'] = getPublishedDateTimestamp(document, url, selectors);
  result['headline'] = getHeadline(document);
  result['description'] = getDescription(document);
  result['imageUrl'] = getImageUrl(document);
  return result;
}

String getImageUrl(Document document) {
  var metaElement = document.querySelector('meta[name*=image],meta[property*=image]');
  if (metaElement != null) {
    return metaElement.attributes['content'];
  }
  return null;
}

String getDescription(Document document) {
  var metaElement = document.querySelector('meta[name*=description],meta[property*=description]');
  if (metaElement != null) {
    return metaElement.attributes['content'];
  }
  return null;
}

String getHeadline(Document document) {
  return document.querySelector('title')?.text?.trim();
}

int getPublishedDateTimestamp(Document document, String url, Map<String, String> selectors) {
  var dateString = getDateString(document, url, selectors);
  if (dateString == '') throw new IgnoreException(url);
  var date = parseDate(dateString, askForDateString(dateString, url));
  return date.millisecondsSinceEpoch;
}

String getDateString(Document document, String url, Map<String, String> selectors) {
  // confidence
  // article time

  // confidence level 1
  // in url
  var urlPattern = new RegExp(r'(\d+[/\-]\d+[/\-]\d+)[/\-]', multiLine: true);
  if (urlPattern.hasMatch(url)) {
    var match = urlPattern.firstMatch(url);
    return match.group(1);
  }
  // [itemprop="datePublished"]
  var itempropElement = document.querySelector('[itemprop="datePublished"],[name="datePublished"]');
  if (itempropElement != null) {
    return getDateStringFromElement(itempropElement);
  }

  // confidence level 2
  // article time
  var articleTimeElement = document
      .querySelector('article time, [class*=article] time, article .date, [class*=article] .date, .timestamp time');
  if (articleTimeElement != null) {
    return getDateStringFromElement(articleTimeElement);
  }

  var metaElement = document.querySelector('meta[name*=published],meta[property*=published]');
  if (metaElement != null) {
    return metaElement.attributes['content'];
  }
  var uri = Uri.parse(url);

  var selector = selectors.containsKey(uri.host) ? selectors[uri.host] : askWhereToFindDate(selectors, uri.host, url);
  try {
    return getDateStringFromElement(document.querySelector(selector));
  } catch (e) {
    throw new IgnoreException(url);
  }
}

String askWhereToFindDate(Map<String, dynamic> selectors, String host, String url) {
  throw new IgnoreException(url);
//  stdout.writeln('Where can I find the date?');
//  var result = stdin.readLineSync().trim();
//  if (result == '') throw new IgnoreException(url);
//  selectors[host] = result;
//  return result;
}

String getDateStringFromElement(Element element) => element.attributes.containsKey('value')
    ? element.attributes['value']
    : element.attributes.containsKey('content')
    ? element.attributes['content']
//        : element.attributes.containsKey('datetime') ? element.attributes['datetime']
    : element.text.trim();

Function askForDateString(String dateString, String url) {
  return () {
    throw new IgnoreException(url);
//    var a = new RegExp(r'(\d{4})[-/.](\d{2})[-/.](\d{2})');
//
//    stdout.writeln('What date should this be in `yyyy-mm-dd`?\n$dateString');
//    var ds = stdin.readLineSync().trim();
//    if (ds == '') throw new IgnoreException(url);
//    var match = a.firstMatch(ds);
//    return new DateTime(int.parse(match.group(1)), int.parse(match.group(2)), int.parse(match.group(3)));
  };
}

DateTime parseDate(String dateString, Function onNothing) {
  const months = const ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
  var yyyy_mm_dd = new RegExp(r'(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})');
  var dd_mm_yyyy = new RegExp(r'(\d{1,2})-(\d{1,2})-(\d{2,4})');
  var mm_dd_yyyy = new RegExp(r'(\d{1,2})[/.](\d{1,2})[/.](\d{2,4})');
  var dd_ago = new RegExp(r'(\d{1,2}) days ago');
  var mmm_dd_yyyy =
  new RegExp(r'.*(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[^\d]* (\d{1,2}).+(\d{4})', caseSensitive: false);
  var dd_mmm_yyyy =
  new RegExp(r'.*(\d{1,2}).+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[^\d]* (\d{4})', caseSensitive: false);

  if (mmm_dd_yyyy.hasMatch(dateString)) {
    var match = mmm_dd_yyyy.firstMatch(dateString);
    return new DateTime(
        int.parse(match.group(3)), months.indexOf(match.group(1).toLowerCase()) + 1, int.parse(match.group(2)));
  }
  if (dd_mmm_yyyy.hasMatch(dateString)) {
    var match = dd_mmm_yyyy.firstMatch(dateString);
    return new DateTime(
        int.parse(match.group(3)), months.indexOf(match.group(2).toLowerCase()) + 1, int.parse(match.group(1)));
  }
  if (yyyy_mm_dd.hasMatch(dateString)) {
    var match = yyyy_mm_dd.firstMatch(dateString);
    return new DateTime(int.parse(match.group(1)), int.parse(match.group(2)), int.parse(match.group(3)));
  }
  if (mm_dd_yyyy.hasMatch(dateString)) {
    var match = mm_dd_yyyy.firstMatch(dateString);
    return new DateTime(int.parse(match.group(3)), int.parse(match.group(1)), int.parse(match.group(2)));
  }
  if (dd_mm_yyyy.hasMatch(dateString)) {
    var match = dd_mm_yyyy.firstMatch(dateString);
    return new DateTime(int.parse(match.group(3)), int.parse(match.group(2)), int.parse(match.group(1)));
  }
  if (dd_ago.hasMatch(dateString)) {
    var match = dd_ago.firstMatch(dateString);
    var daysAgoDate = new DateTime.now().add(new Duration(days: -int.parse(match.group(1))));
    return new DateTime(daysAgoDate.year, daysAgoDate.month, daysAgoDate.day);
  }
  return onNothing();
}

class IgnoreException extends StateError {
  IgnoreException(String url) : super(url);
}
