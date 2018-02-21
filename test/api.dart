import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

const baseUrl = 'http://localhost:8080';
main() async {

  test('get', () async {
    var response = await http.get('$baseUrl/story');
    var json = JSON.decode(response.body);
    expect(json, new isInstanceOf<Map>());
  });

  test("post", () async {

    var edits = {
      "61": [
        {
          "type": "textPart",
          "markdown": "asdfasdfasasdfasdf"
        }
      ]
    };
    var body = JSON.encode({'accessCode': 'B2LXVfxuJdrQTn6FjHQjeGvGfhGVj6Qx', 'edits': edits});
    var request = await http.post('$baseUrl/story', body: body);

    expect(request.statusCode, 200);
  });


}