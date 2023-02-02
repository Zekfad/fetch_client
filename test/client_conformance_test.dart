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

  group('client conformance tests with probe mode', () {
    testAll(
      () => FetchClient(
        mode: RequestMode.cors,
        redirectPolicy: RedirectPolicy.probe,
      ),
      canStreamRequestBody: false,
      canStreamResponseBody: true,
      redirectAlwaysAllowed: true,
    );
  });

  group('client conformance tests with probeHead mode', () {
    testAll(
      () => FetchClient(
        mode: RequestMode.cors,
        redirectPolicy: RedirectPolicy.probeHead,
      ),
      canStreamRequestBody: false,
      canStreamResponseBody: true,
      redirectAlwaysAllowed: true,
    );
  });

  // Fails with ERR_H2_OR_QUIC_REQUIRED
  // That means server must support request streaming is some special form
  // or something.
  // group('client conformance tests with streaming mode', () {
  //   testAll(
  //     () => FetchClient(
  //       mode: RequestMode.cors,
  //       streamRequests: true,
  //     ),
  //     canStreamRequestBody: true,
  //     canStreamResponseBody: true,
  //     redirectAlwaysAllowed: true,
  //   );
  // });
}
