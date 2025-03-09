@TestOn('browser')
library;

import 'package:fetch_client/fetch_client.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';


void main() {
  group('cancel test', () {
    final client = FetchClient(mode: RequestMode.cors);
    final uri = Uri.parse('https://raw.githubusercontent.com/Zekfad/fetch_client/22c3a2732c4a89ef284827cba4a7e62a01535776/LICENSE');

    test('throw error when request is canceled', () async {
      final request = FetchRequest(
        Request('GET', uri),
      );
      final response = await client.send(request);
      response.cancel();

      await expectLater(
        response.stream.bytesToString(),
        throwsA(isA<RequestCanceledException>()),
      );
    });

    test('throw error when request is canceled with provided reason', () async {
      const reason = 'cancel reason';
      final request = FetchRequest(
        Request('GET', uri),
      );
      final response = await client.send(request);
      response.cancel(reason);

      await expectLater(
        response.stream.bytesToString(),
        throwsA(
          const TypeMatcher<RequestCanceledException>().having(
            (e) => e.reason,
            'reason must be as provided',
            equals(reason),
          ),
        ),
      );
    });
  });
}
