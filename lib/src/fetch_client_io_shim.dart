/// This shim library mimics FetchClient to allow imports from non-JS platforms.
/// @nodoc
// ignore: unnecessary_library_name
library fetch_client_io_shim;

import 'package:fetch_api/enums.dart';
import 'package:http/http.dart' show BaseClient, BaseRequest;
import 'fetch_response.dart';
import 'redirect_policy.dart';


/// @nodoc
class FetchClient extends BaseClient {
  /// @nodoc
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

  /// @nodoc
  final RequestMode mode;

  /// @nodoc
  final RequestCredentials credentials;

  /// @nodoc
  final RequestCache cache;

  /// @nodoc
  final String referrer;

  /// @nodoc
  final RequestReferrerPolicy referrerPolicy;

  /// @nodoc
  final RedirectPolicy redirectPolicy;

  /// @nodoc
  final bool streamRequests;

  @override
  Future<FetchResponse> send(BaseRequest request) async => throw UnsupportedError('Unsupported platform');

  @override
  void close() => throw UnsupportedError('Unsupported platform');
}
