@TestOn('browser')
library;

import 'package:fetch_client/fetch_client.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';


void main() {
  group('integrity tests', () {
    final client = FetchClient(mode: RequestMode.cors);
    final uri = Uri.parse('https://raw.githubusercontent.com/Zekfad/fetch_client/22c3a2732c4a89ef284827cba4a7e62a01535776/LICENSE');

    test('throw error when integrity mismatch', () async {
      const integrity = 'sha256-0';
      final request = FetchRequest(
        Request('GET', uri),
      )..integrity = integrity;
      await expectLater(
        client.send(request),
        throwsA(isA<ClientException>()),
      );
    });

    test('succeed with correct integrity', () async {
      const integrity = 'sha256-NTaW0fWGbetqbg/iB0CfyvrxlEvm4rk3f1MXq+Zu0S8=';
      final request = FetchRequest(
        Request('GET', uri),
      )..integrity = integrity;
      final response = await client.send(request);
      expect(response.statusCode, 200);
    });
  });
}
