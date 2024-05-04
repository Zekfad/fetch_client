import 'package:fetch_api/enums.dart';
import 'package:http/http.dart';

import 'fetch_client.dart' if (dart.library.io) 'fetch_client_io_shim.dart';
import 'fetch_response.dart';
import 'on_done.dart';
import 'redirect_policy.dart';


/// Wraps request to provide fetch options overrides. 
class FetchRequest<T extends BaseRequest> implements BaseRequest {
  // Create new fetch request.
  FetchRequest(this.request);

  /// Inner request to send.
  final T request;

  @override
  String get method => request.method;
  
  @override
  Uri get url => request.url;

  @override
  int? get contentLength => request.contentLength;
  @override
  set contentLength(int? value) => request.contentLength = value;

  @override
  bool get persistentConnection => request.persistentConnection;
  @override
  set persistentConnection(bool value) => request.persistentConnection = value;

  @override
  bool get followRedirects => request.followRedirects;
  @override
  set followRedirects(bool value) => request.followRedirects = value;

  @override
  int get maxRedirects => request.maxRedirects;
  @override
  set maxRedirects(int value) => request.maxRedirects = value;

  @override
  Map<String, String> get headers => request.headers;

  @override
  bool get finalized => request.finalized;

  /// The subresource integrity value of the request
  /// (e.g.,`sha256-BpfBw7ivV8q2jLiT13fxDYAe2tJllusRSZ273h2nFSE=`).
  String? get integrity => _integrity;
  String? _integrity;

  set integrity(String? value) {
    _checkFinalized();
    _integrity = value;
  }

  /// The mode of the request.
  RequestMode? get mode => _mode;
  RequestMode? _mode;

  set mode(RequestMode? value) {
    _checkFinalized();
    _mode = value;
  }

  /// The credentials mode, defines what browsers do with credentials (cookies,
  /// HTTP authentication entries, and TLS client certificates).
  RequestCredentials? get credentials => _credentials;
  RequestCredentials? _credentials;

  set credentials(RequestCredentials? value) {
    _checkFinalized();
    _credentials = value;
  }

  /// The cache mode which controls how the request will interact with
  /// the browser's HTTP cache.
  RequestCache? get cache => _cache;
  RequestCache? _cache;

  set cache(RequestCache? value) {
    _checkFinalized();
    _cache = value;
  }

  /// The referrer of the request.
  /// This can be a same-origin URL, `about:client`, or an empty string.
  String? get referrer => _referrer;
  String? _referrer;

  set referrer(String? value) {
    _checkFinalized();
    _referrer = value;
  }

  /// The referrer policy of the request.
  RequestReferrerPolicy? get referrerPolicy => _referrerPolicy;
  RequestReferrerPolicy? _referrerPolicy;

  set referrerPolicy(RequestReferrerPolicy? value) {
    _checkFinalized();
    _referrerPolicy = value;
  }

  /// The redirect policy of the request, defines how client should handle
  /// [BaseRequest.followRedirects].
  RedirectPolicy? get redirectPolicy => _redirectPolicy;
  RedirectPolicy? _redirectPolicy;

  set redirectPolicy(RedirectPolicy? value) {
    _checkFinalized();
    _redirectPolicy = value;
  }

  /// Throws an error if this request has been finalized.
  void _checkFinalized() {
    if (!finalized)
      return;
    throw StateError("Can't modify a finalized Request.");
  }

  @override
  ByteStream finalize() => request.finalize();

  @override
  Future<StreamedResponse> send() async {
    final client = FetchClient();

    try {
      final response = await client.send(this);
      final stream = onDone(response.stream, client.close);
      return FetchResponse(
        stream,
        response.statusCode,
        cancel: response.cancel,
        url: response.url,
        redirected: response.redirected,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
        contentLength: response.contentLength,
      );
    } catch(_) {
      client.close();
      rethrow;
    }
  }
}
