import 'dart:convert';
import 'dart:typed_data';

import 'package:fetch_client/fetch_client.dart';
import 'package:http/http.dart';


void main(List<String> args) async {
  final client = FetchClient(
    mode: RequestMode.cors,
    streamRequests: true,
  );

  final uri = Uri.https('api.restful-api.dev', 'objects');

  final stream = (() async* {
    yield Uint8List.fromList(
      '''
      {
        "name": "My cool data",
        "data": {
          "data_part_1": "part_1",
      '''.codeUnits,
    );
    await Future<void>.delayed(const Duration(seconds: 1));
    yield Uint8List.fromList(
      '''
          "data_part_2": "part_2"
        }
      }
      '''.codeUnits,
    );
  })();

  final request = StreamedRequest('POST', uri)..headers.addAll({
    'content-type': 'application/json',
  });

  stream.listen(
    request.sink.add,
    onDone: request.sink.close,
    onError: request.sink.addError,
  );

  final response = await client.send(request);

  print(await utf8.decodeStream(response.stream));
}
