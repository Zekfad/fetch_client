import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:fetch_api/fetch_api.dart';
import 'package:http/http.dart' show BaseClient, BaseRequest, ClientException;
import 'cancel_callback.dart';
import 'fetch_request.dart';
import 'fetch_response.dart';
import 'on_done.dart';
import 'redirect_policy.dart';
import 'request_canceled_exception.dart';


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
/// * [FetchClient.streamRequests] is supported only in __Chromium 105+__ based
///   browsers and requires server to be HTTP/2 or HTTP/3.
///   
///   See [compatibility chart](https://developer.mozilla.org/en-US/docs/Web/API/Request#browser_compatibility)
///   and [Chrome Developers blog](https://developer.chrome.com/articles/fetch-streaming-requests/#doesnt-work-on-http1x)
///   for more info.
class FetchClient extends BaseClient {
  /// Create new HTTP client based on Fetch API.
  FetchClient({
    this.mode = RequestMode.noCors,
    this.credentials = RequestCredentials.sameOrigin,
    this.cache = RequestCache.byDefault,
    this.referrer = '',
    this.referrerPolicy = RequestReferrerPolicy.strictOriginWhenCrossOrigin,
    this.redirectPolicy = RedirectPolicy.alwaysFollow, 
    this.streamRequests = false,
  });

  /// The default request mode.
  /// 
  /// Mode is used to determine if cross-origin requests lead to valid
  /// responses, and which properties of the response are readable.
  final RequestMode mode;

  /// The default credentials mode, defines what browsers do with credentials
  /// (cookies, HTTP authentication entries, and TLS client certificates).
  final RequestCredentials credentials;

  /// The default cache mode which controls how requests will interact with
  /// the browser's HTTP cache.
  final RequestCache cache;

  /// The default referrer.
  /// This can be a same-origin URL, `about:client`, or an empty string.
  final String referrer;

  /// The default referrer policy.
  final RequestReferrerPolicy referrerPolicy;

  /// The default redirect policy, defines how client should handle
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

  final _abortCallbacks = <CancelCallback>[];

  var _closed = false;

  @override
  Future<FetchResponse> send(BaseRequest request) async {
    if (_closed)
      throw ClientException('Client is closed', request.url);
    final requestMethod = request.method.toUpperCase();
    final byteStream = request.finalize();
    final RequestBody? body;
    final int bodySize;
    if (['GET', 'HEAD'].contains(requestMethod)) {
      body = null;
      bodySize = 0;
    } else if (streamRequests) {
      body = RequestBody.fromReadableStream(
        ReadableStream(
          ReadableStreamSource.fromStream(
            byteStream.transform(
              StreamTransformer.fromHandlers(
                handleData: (data, sink) => sink.add(
                  (data is Uint8List
                    ? data
                    : Uint8List.fromList(data)).toJS,
                ),
              ),
            ),
          ),
        ),
      );
      bodySize = -1;
    } else {
      final bytes = await byteStream.toBytes();
      body = bytes.isEmpty
        ? null
        : RequestBody.fromJSTypedArray(bytes.toJS);
      bodySize = bytes.lengthInBytes;
    }

    final abortController = AbortController<JSString>();

    final fetchRequest = request is! FetchRequest ? null : request;
    final init = FetchOptions(
      body: body,
      method: request.method,
      redirect: (
        request.followRedirects ||
        (fetchRequest?.redirectPolicy ?? redirectPolicy) == RedirectPolicy.alwaysFollow
      )
        ? RequestRedirect.follow
        : RequestRedirect.manual,
      headers: Headers.fromMap(request.headers),
      mode: fetchRequest?.mode ?? mode,
      credentials: fetchRequest?.credentials ?? credentials,
      cache: fetchRequest?.cache ?? cache,
      referrer: fetchRequest?.referrer ?? referrer,
      referrerPolicy: fetchRequest?.referrerPolicy ?? referrerPolicy,
      integrity: fetchRequest?.integrity ?? '',
      keepalive: bodySize < 63 * 1024 && !streamRequests && request.persistentConnection,
      signal: abortController.signal,
      duplex: !streamRequests ? null : RequestDuplex.half,
    );

    final Response response;
    try {
      response = await _abortOnCloseSafeGuard(
        () => fetch(request.url.toString(), init),
        abortController,
      );

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

    if (response.body == null && requestMethod != 'HEAD')
      throw StateError('Invalid state: missing body with non-HEAD request.');

    final reader = response.body?.getReader();

    late final CancelCallback abort;
    abort = ([ reason, ]) {
      _abortCallbacks.remove(abort);
      reader?.cancel();
      abortController.abort(reason?.toJS);
    };
    _abortCallbacks.add(abort);

    final int? contentLength;
    final int? expectedBodyLength;
    if (response.headers.get('Content-Length') case final value?) {
      contentLength = int.tryParse(value);
      if (contentLength == null || contentLength < 0)
        throw ClientException('Content-Length header must be a positive integer value.', request.url);

      // Although `identity` SHOULD NOT be used in the Content-Encoding
      // according to [RFC 2616](https://www.rfc-editor.org/rfc/rfc2616#section-3.5),
      // we'll handle this edge case anyway.
      final encoding = response.headers.get('Content-Encoding');
      if (response.responseType == ResponseType.cors) {
        // For cors response we should ensure that we actually have access to
        // Content-Encoding header, otherwise response can be encoded but
        // we won't be able to detect it.
        final exposedHeaders = response.headers.get('Access-Control-Expose-Headers')?.toLowerCase();
        if (exposedHeaders != null && (
          exposedHeaders.contains('*') ||
          exposedHeaders.contains('content-encoding')
        ) && (
          encoding == null ||
          encoding.toLowerCase() == 'identity'
        ))
          expectedBodyLength = contentLength;
        else
          expectedBodyLength = null;
      } else {
        // In non-cors response we have access to Content-Encoding header
        if (encoding == null || encoding.toLowerCase() == 'identity')
          expectedBodyLength = contentLength;
        else
          expectedBodyLength = null;
      }
    } else {
      contentLength = null;
      expectedBodyLength = null;
    }

    final stream = onDone(
      reader == null
        ? const Stream<Uint8List>.empty()
        : _readAsStream(
          reader: reader,
          expectedLength: expectedBodyLength,
          uri: request.url,
          abortController: abortController,
        ),
      abort,
    );

    return FetchResponse(
      stream,
      response.status,
      cancel: abort,
      url: Uri.parse(response.url),
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
    required AbortController<JSString> abortController,
  }) async {
    init.requestRedirect = RequestRedirect.follow;

    if (redirectPolicy == RedirectPolicy.probeHead)
      init.method = 'HEAD';
    else
      init.method = 'GET';

    final Response response;
    try {
      response = await _abortOnCloseSafeGuard(
        () => fetch(request.url.toString(), init),
        abortController,
      );

      // Cancel before even reading response
      if (redirectPolicy == RedirectPolicy.probe)
        abortController.abort();
    } catch (e) {
      throw ClientException('Failed to execute probe fetch: $e', request.url);
    }

    return FetchResponse(
      const Stream.empty(),
      302,
      cancel: ([ reason, ]) {},
      url: Uri.parse(initialResponse.url),
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

  /// Aborts [abortController] if [close] is called while preforming an [action]. 
  Future<T> _abortOnCloseSafeGuard<T>(
    Future<T> Function() action,
    AbortController<JSString> abortController,
  ) async {
    late final CancelCallback abortOnCloseSafeGuard;
    abortOnCloseSafeGuard = ([ reason, ]) {
      _abortCallbacks.remove(abortOnCloseSafeGuard);
      abortController.abort(reason?.toJS);
    };
    _abortCallbacks.add(abortOnCloseSafeGuard);
    try {
      // Await is mandatory here.
      return await action();
    } finally {
      // Abort wont make a difference anymore, so we remove unnecessary
      // reference.
      _abortCallbacks.remove(abortOnCloseSafeGuard);
    }
  }

  /// Reads [reader] via [ReadableStreamDefaultReader.readAsStream] and
  /// optionally checks that read data have [expectedLength].
  Stream<Uint8List> _readAsStream<AbortType extends JSAny>({
    required ReadableStreamDefaultReader<JSUint8Array, AbortType> reader,
    required int? expectedLength,
    required Uri uri,
    required AbortController<JSString> abortController,
  }) async* {
    final stream = reader.readAsStream();
    var length = 0;

    try {
      await for (final JSUint8Array(toDart: chunk) in stream) {
        yield chunk;
        length += chunk.lengthInBytes;
        if (expectedLength != null && length > expectedLength)
          throw ClientException('Content-Length is smaller than actual response length.', uri);
      }
      // check if closed after stream is read, because canceling just forces
      // reader to close shortly without throwing an exception
      if (abortController.signal case AbortSignal(aborted: true, :final reason))
        throw RequestCanceledException(reason?.toDart ?? '', uri);
      if (expectedLength != null && length < expectedLength)
        throw ClientException('Content-Length is larger than actual response length.', uri);
    } on ClientException {
      rethrow;
    } catch (e) {
      throw ClientException('Error occurred while reading response body: $e', uri);
    }
  }

  /// Closes the client.
  ///
  /// This method also terminates all associated active requests.
  @override
  void close() {
    if (!_closed) {
      _closed = true;
      for (final abort in _abortCallbacks.toList())
        abort('Client closed');
    }
  }
}
