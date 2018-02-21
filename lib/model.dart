import 'package:q_tools/persistence.dart';

class Image {
  Uri url;
  String filename;
}

class Post extends Entity {
  String id;
  String userId;
  String subject;
  String name;
  String email;
  String trip;
  String text;
  List<Image> images;
  String threadId;
  String source;
  String link;
  List<Post> references;
  DateTime date;
  DateTime deletedDate;
}

class Link extends Entity {
  String id;
  Uri url;
  DateTime date;
  String headline;
  String description;
  Uri imageUrl;
}

class Comment extends Entity {
  String id;
  String markdown;
  String username;
  DateTime lastEditedDate;
}

class User extends Entity {
  String id;
  String get name => id;
  String password;
}

class ServerConfig {
  Uri serverUrl;
  Uri webClientUrl;
}