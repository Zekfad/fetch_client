@TestOn('browser')
library;

import 'package:fetch_client/fetch_client.dart';
import 'package:http_client_conformance_tests/http_client_conformance_tests.dart';
import 'package:test/test.dart';


void main() {
  group('client conformance tests', () {
    testAll(
      () => FetchClient(mode: RequestMode.cors),
      canStreamRequestBody: false,
      canStreamResponseBody: true,
      redirectAlwaysAllowed: true,
    );
  });
}
