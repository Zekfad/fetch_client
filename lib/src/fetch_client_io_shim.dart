/// This shim library mimics FetchClient to allow imports from non-JS platforms.
/// @nodoc
library fetch_client_io_shim;

import 'package:fetch_api/enums.dart';
import 'package:http/http.dart' show BaseClient, BaseRequest;
import 'fetch_response.dart';
import 'redirect_policy.dart';


class FetchClient extends BaseClient {
  FetchClient({
    this.mode = RequestMode.noCors,
    this.credentials = RequestCredentials.sameOrigin,
    this.cache = RequestCache.byDefault,
    this.referrer = '',
    this.referrerPolicy = RequestReferrerPolicy.strictOriginWhenCrossOrigin,
    this.redirectPolicy = RedirectPolicy.alwaysFollow, 
    this.streamRequests = false,
  }) {
    throw UnsupportedError('Unsupported platform');
  }

  final RequestMode mode;
  final RequestCredentials credentials;
  final RequestCache cache;
  final String referrer;
  final RequestReferrerPolicy referrerPolicy;
  final RedirectPolicy redirectPolicy;
  final bool streamRequests;

  @override
  Future<FetchResponse> send(BaseRequest request) async => throw UnsupportedError('Unsupported platform');

  @override
  void close() => throw UnsupportedError('Unsupported platform');
}
