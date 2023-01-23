import 'dart:convert';

import 'package:fetch_client/fetch_client.dart';
import 'package:http/http.dart';


void main() async {
  final client = FetchClient(mode: RequestMode.cors);
  final uri = Uri.https('jsonplaceholder.typicode.com', '/todos/1');
  final response = await client.send(Request('GET', uri));

  print(response.redirected);
  print(response.url);

  print(await utf8.decodeStream(response.stream));
}
