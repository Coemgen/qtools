import 'package:q_tools/model.dart';
import 'package:q_tools/persistence.dart';

const imageSerializer = const ImageSerializer();
const postSerializer = const PostSerializer();
const linkSerializer = const LinkSerializer();
const userSerializer = const UserSerializer();
const commentSerializer = const CommentSerializer();
const serverConfigSerializer = const ServerConfigSerializer();

class ImageSerializer extends Serializer<Image> {
  const ImageSerializer();

  @override
  Image fromJson(Map input) => new Image()
    ..filename = input['filename']
    ..url = Uri.parse(input['url']);

  @override
  Map toJson(Image input) => {
        'url': input.url.toString(),
        'filename': input.filename,
      };
}

class PostSerializer extends Serializer<Post> {
  const PostSerializer();

  Post fromJson(Map input) => new Post()
    ..id = input['id']
    ..source = input['source']
    ..images = input['images']?.map(imageSerializer.fromJson)?.toList()
    ..text = input['text']
    ..trip = input['trip']
    ..email = input['email']
    ..name = input['name']
    ..subject = input['subject']
    ..date = new DateTime.fromMillisecondsSinceEpoch(input['timestamp'] * 1000, isUtc: true)
    ..deletedDate = input.containsKey('timestampDeletion')
        ? new DateTime.fromMillisecondsSinceEpoch(input['timestampDeletion'] * 1000, isUtc: true)
        : null
    ..link = input['link']
    ..userId = input['userId']
    ..references = input['references']?.map(fromJson)?.toList()
    ..threadId = input['threadId'];

  Map<String, dynamic> toJson(Post p) => {
        'id': p.id,
        'userId': p.userId,
        'timestamp': p.date.millisecondsSinceEpoch / 1000,
        'subject': p.subject,
        'name': p.name,
        'email': p.email,
        'trip': p.trip,
        'text': p.text,
        'images': p.images.map(imageSerializer.toJson).toList(),
        'threadId': p.threadId,
        'source': p.source,
        'link': p.link,
        'references': p.references.map(toJson).toList(),
      };
}

class LinkSerializer extends Serializer<Link> {
  const LinkSerializer();

  @override
  Link fromJson(Map input) => new Link()
    ..date = new DateTime.fromMillisecondsSinceEpoch(input['date'])
    ..imageUrl = Uri.parse(input['imageUrl'])
    ..description = input['description']
    ..headline = input['headline']
    ..id = input['id'];

  @override
  Map toJson(Link input) => {
        "id": input.id,
        "url": input.url.toString(),
        "date": input.date.millisecondsSinceEpoch,
        "headline": input.headline,
        "description": input.description,
        "imageUrl": input.imageUrl.toString(),
      };
}

class CommentSerializer extends Serializer<Comment> {
  const CommentSerializer();

  @override
  Comment fromJson(Map input) => new Comment()
    ..lastEditedDate = new DateTime.fromMillisecondsSinceEpoch(input['lastEditedDate'], isUtc: true)
    ..markdown = input['markdown']
    ..username = input['username']
    ..id = input['id'];

  @override
  Map toJson(Comment input) => {
        "id": input.id,
        "lastEditedDate": input.lastEditedDate.millisecondsSinceEpoch,
        "username": input.username,
        "markdown": input.markdown,
      };
}

class UserSerializer extends Serializer<User> {
  const UserSerializer();

  @override
  User fromJson(Map input) => new User()
    ..id = input['id']
    ..password = input['password'];

  @override
  Map toJson(User input) => {
        "id": input.id,
        "password": input.password,
      };
}

class ServerConfigSerializer extends Serializer<ServerConfig> {
  const ServerConfigSerializer();

  @override
  ServerConfig fromJson(Map input) => new ServerConfig()
    ..serverUrl = Uri.parse(input['serverUrl'])
    ..webClientUrl = Uri.parse(input['webClientUrl']);

  @override
  Map toJson(ServerConfig input) => {
        "serverUrl": input.serverUrl.toString(),
        "webClientUrl": input.webClientUrl.toString(),
      };
}
