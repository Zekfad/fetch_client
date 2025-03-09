import 'package:http/http.dart' show BaseResponseWithUrl, StreamedResponse;

import 'cancel_callback.dart';


/// [StreamedResponse] with additional capability to [cancel] request and access
/// to final (after redirects) request [url].
class FetchResponse extends StreamedResponse implements BaseResponseWithUrl {
  /// Creates a new cancelable streaming response.
  ///
  /// [stream] should be a single-subscription stream.
  FetchResponse(super.stream, super.statusCode, {
    required this.cancel,
    required this.url,
    required this.redirected,
    super.contentLength,
    super.request,
    super.headers,
    super.isRedirect,
    super.persistentConnection,
    super.reasonPhrase,
  });

  /// Cancels current request.
  final CancelCallback cancel;

  /// Target resource url (the one after redirects, if there are some).
  @override
  final Uri url;

  /// Whether browser was redirected before loading actual resource.
  final bool redirected;
}
