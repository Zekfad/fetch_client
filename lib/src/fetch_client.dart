import 'dart:js_interop';

import 'package:fetch_api/fetch_api.dart';
import 'package:http/http.dart' show BaseClient, BaseRequest, ClientException;
import 'fetch_response.dart';
import 'on_done.dart';
import 'redirect_policy.dart';


/// HTTP client based on Fetch API.
/// It does support streaming and can handle non 200 responses.
/// 
/// This implementation has some restrictions:
/// * [BaseRequest.persistentConnection] is translated to
///   [FetchOptions.keepalive] (if [streamRequests] is disabled).
/// * [BaseRequest.contentLength] is ignored.
/// * When [BaseRequest.followRedirects] is `true` you can get redirect
///   information via [FetchResponse.redirected] and [FetchResponse.url]).
///   If [BaseRequest.followRedirects] is `false` [redirectPolicy] takes place
///   and dictates [FetchClient] actions.
/// * [BaseRequest.maxRedirects] is ignored. 
class FetchClient extends BaseClient {
  FetchClient({
    this.mode = RequestMode.noCors,
    this.credentials = RequestCredentials.sameOrigin,
    this.cache = RequestCache.byDefault,
    this.referrer = '',
    this.referrerPolicy = RequestReferrerPolicy.strictOriginWhenCrossOrigin,
    this.integrity = '',
    this.redirectPolicy = RedirectPolicy.alwaysFollow, 
    this.streamRequests = false,
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

  /// Client redirect policy, defines how client should handle
  /// [BaseRequest.followRedirects].
  final RedirectPolicy redirectPolicy;

  /// Whether to use [ReadableStream] as body for requests streaming.
  /// 
  /// **NOTICE**: This feature is supported only in __Chromium 105+__ based browsers and
  /// requires server to be HTTP/2 or HTTP/3.
  /// 
  /// See [compatibility chart](https://developer.mozilla.org/en-US/docs/Web/API/Request#browser_compatibility)
  /// and [Chrome Developers blog](https://developer.chrome.com/articles/fetch-streaming-requests/#doesnt-work-on-http1x)
  /// for more info.
  final bool streamRequests;

  final _abortCallbacks = <void Function()>[];

  var _closed = false;

  @override
  Future<FetchResponse> send(BaseRequest request) async {
    if (_closed)
      throw ClientException('Client is closed', request.url);

    final byteStream = request.finalize();
    final RequestBody? body;
    final int bodySize;
    if (['GET', 'HEAD'].contains(request.method.toUpperCase())) {
      body = null;
      bodySize = 0;
    } else if (streamRequests) {
      body = RequestBody.fromReadableStream(
        ReadableStream(
          ReadableStreamSource.fromStream(byteStream.cast<JSNumber>()),
        ),
      );
      bodySize = -1;
    } else {
      final bytes = await byteStream.toBytes();
      body = bytes.isEmpty
        ? null
        : RequestBody.fromTypedData(bytes);
      bodySize = bytes.lengthInBytes;
    }

    final abortController = AbortController();
    final init = FetchOptions(
      body: body,
      method: request.method,
      redirect: (request.followRedirects || redirectPolicy == RedirectPolicy.alwaysFollow)
        ? RequestRedirect.follow
        : RequestRedirect.manual,
      headers: Headers.fromMap(request.headers),
      mode: mode,
      credentials: credentials,
      cache: cache,
      referrer: referrer,
      referrerPolicy: referrerPolicy,
      keepalive: bodySize < 63 * 1024 && !streamRequests && request.persistentConnection,
      signal: abortController.signal,
      duplex: !streamRequests ? null : RequestDuplex.half,
    );

    late final void Function() abortRequest;
    abortRequest = () {
      _abortCallbacks.remove(abortRequest);
      abortController.abort();
    };
    _abortCallbacks.add(abortRequest);

    final Response response;
    try {
      response = await fetch(request.url.toString(), init);

      if (
        response.type == 'opaqueredirect' &&
        !request.followRedirects &&
        redirectPolicy != RedirectPolicy.alwaysFollow
      )
        return _probeRedirect(
          request: request,
          initialResponse: response,
          init: init,
          abortController: abortController,
        );
    } catch (e) {
      throw ClientException('Failed to execute fetch: $e', request.url);
    }

    if (response.status == 0)
      throw ClientException(
        'Fetch response status code 0',
        request.url,
      );

    final reader = response.body!.getReader();
	
    _abortCallbacks.remove(abortRequest);

    late final void Function() abort;
    abort = () {
      _abortCallbacks.remove(abort);
      reader.cancel();
      abortController.abort();
    };
    _abortCallbacks.add(abort);

    final stream = onDone(reader.readAsStream(), abort);
    final int? contentLength;
    if (response.headers.get('Content-Length') case final value?) {
      contentLength = int.tryParse(value);
      if (contentLength == null || contentLength < 0)
        throw ClientException('Content-Length header must be a positive integer value.');
    } else
      contentLength = null;

    return FetchResponse(
      stream,
      response.status,
      cancel: abort,
      url: response.url,
      redirected: response.redirected,
      request: request,
      headers: {
        for (final (name, value) in response.headers.entries())
          name: value,
      },
      isRedirect: false,
      persistentConnection: false,
      reasonPhrase: response.statusText,
      contentLength: contentLength,
    );
  }

  /// Makes probe request and returns "redirect" response.
  Future<FetchResponse> _probeRedirect({
    required BaseRequest request,
    required Response initialResponse,
    required FetchOptions init,
    required AbortController abortController,
  }) async {
    init.requestRedirect = RequestRedirect.follow;

    if (redirectPolicy == RedirectPolicy.probeHead)
      init.method = 'HEAD';
    else
      init.method = 'GET';

    final Response response;
    try {
      response = await fetch(request.url.toString(), init);

      // Cancel before even reading response
      if (redirectPolicy == RedirectPolicy.probe)
        abortController.abort();
    } catch (e) {
      throw ClientException('Failed to execute probe fetch: $e', request.url);
    }

    return FetchResponse(
      const Stream.empty(),
      302,
      cancel: () {},
      url: initialResponse.url,
      redirected: false,
      request: request,
      headers: {
        for (final (name, value) in response.headers.entries())
          name: value,
        'location': response.url,
      },
      isRedirect: true,
      persistentConnection: false,
      reasonPhrase: 'Found',
      contentLength: null,
    );
  }

  /// Closes the client.
  ///
  /// This method also terminates all associated active requests.
  @override
  void close() {
    if (!_closed) {
      _closed = true;
      for (final abort in _abortCallbacks.toList())
        abort();
    }
  }
}
