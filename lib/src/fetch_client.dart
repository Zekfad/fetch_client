import 'package:fetch_api/compatibility_layer.dart' as fetch_compatibility_layer;
import 'package:fetch_api/fetch_api.dart';
import 'package:http/http.dart' show BaseClient, BaseRequest, BaseResponse, ClientException;
import 'fetch_response.dart';
import 'on_done.dart';


/// HTTP client based on Fetch API.
/// It does support streaming and can handle non 200 responses.
/// 
/// This implementation has some restrictions:
/// * [BaseRequest.persistentConnection] is translated to
///   [RequestInit.keepalive].
/// * [BaseRequest.contentLength] is ignored.
/// * When [BaseRequest.followRedirects] is `false` request will throw, but
///   without any helpful information (this is the limitation of Fetch, if you
///   need to get target URL, rely on [FetchResponse.redirected] and 
///   [FetchResponse.url]).
/// * [BaseRequest.maxRedirects] is ignored. 
class FetchClient extends BaseClient {
  FetchClient({
    this.mode = RequestMode.noCors,
    this.credentials = RequestCredentials.sameOrigin,
    this.cache = RequestCache.byDefault,
    this.referrer = '',
    this.referrerPolicy = RequestReferrerPolicy.strictOriginWhenCrossOrigin,
    this.integrity = '',
  });

  /// The mode you want to use for the request
  final RequestMode mode;

  /// Controls what browsers do with credentials (cookies, HTTP authentication
  /// entries, and TLS client certificates).
  final RequestCredentials credentials;

  /// A string indicating how the request will interact with the browser's
  /// HTTP cache.
  final RequestCache cache;

  /// A string specifying the referrer of the request.
  /// This can be a same-origin URL, `about:client`, or an empty string.
  final String referrer;

  /// Specifies the referrer policy to use for the request.
  final RequestReferrerPolicy referrerPolicy;

  /// Contains the subresource integrity value of the request
  /// (e.g.,`sha256-BpfBw7ivV8q2jLiT13fxDYAe2tJllusRSZ273h2nFSE=`)
  final String integrity;

  final _abortCallbacks = <void Function()>[];

  var _closed = false;

  @override
  Future<FetchResponse> send(BaseRequest request) async {
    if (_closed)
      throw ClientException('Client is closed', request.url);

    final body = await request.finalize().toBytes();
    final abortController = AbortController();
    final init = fetch_compatibility_layer.createRequestInit(
      body: body.isEmpty ? null : body,
      method: request.method,
      redirect: request.followRedirects
        ? RequestRedirect.follow
        : RequestRedirect.error,
      headers: fetch_compatibility_layer.createHeadersFromMap(request.headers),
      mode: mode,
      credentials: credentials,
      cache: cache,
      referrer: referrer,
      referrerPolicy: referrerPolicy,
      keepalive: request.persistentConnection,
      signal: abortController.signal,
    );

    final Response response;
    try {
      response = await fetch(request.url.toString(), init);
    } catch (e) {
      throw ClientException('Failed to execute fetch: $e', request.url);
    }

    if (response.status == 0)
      throw ClientException(
        'Fetch response status code 0',
        request.url,
      );

    final reader = response.body!.getReader();

    late final void Function() abort;
    abort = () {
      _abortCallbacks.remove(abort);
      reader.cancel<dynamic>();
      abortController.abort();
    };
    _abortCallbacks.add(abort);

    final stream = onDone(reader.readAsStream(), abort);
    final contentLength = response.headers.get('Content-Length');

    return FetchResponse(
      stream,
      response.status,
      cancel: abort,
      url: response.url,
      redirected: response.redirected,
      request: request,
      headers: {
        for (final header in response.headers.entries())
          header.first: header.last,
        if (response.redirected)
          'location': response.url,
      },
      isRedirect: false,
      persistentConnection: false,
      reasonPhrase: response.statusText,
      contentLength: contentLength == null ? null
        : int.tryParse(contentLength),
    );
  }

  /// Closes the client.
  ///
  /// This terminates all active requests.
  @override
  void close() {
    if (!_closed) {
      _closed = true;
      for (final abort in _abortCallbacks.toList())
        abort();
    }
  }
}
