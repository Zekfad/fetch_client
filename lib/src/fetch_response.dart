import 'package:http/http.dart' show StreamedResponse;


/// [StreamedResponse] with additional capability to [cancel] request and access
/// to final (after redirects) request [url].
class FetchResponse extends StreamedResponse {
  /// Creates a new cancelable streaming response.
  ///
  /// [stream] should be a single-subscription stream.
  FetchResponse(super.stream, super.statusCode, {
    required this.cancel,
    required this.url,
    super.contentLength,
    super.request,
    super.headers,
    super.isRedirect,
    super.persistentConnection,
    super.reasonPhrase,
  });

  /// Cancels current request.
  final void Function() cancel;

  final String url;
}
