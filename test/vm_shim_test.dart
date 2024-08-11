@TestOn('vm')
library;

import 'package:fetch_client/fetch_client.dart';
import 'package:test/test.dart';


void main() {
  group('vm shim test', () {
    test('doesn\'t prevent import in vm environment', () {
      expect(RequestMode.cors.toString(), equals('cors'));
    });

    test('throws unsupported error in vm', () {
      expect(FetchClient.new, anyOf(throwsUnsupportedError));
    });
  });
}
