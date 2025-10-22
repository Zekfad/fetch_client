import 'package:http/http.dart';


/// An exception caused by canceling the request.
class RequestCanceledException extends ClientException implements RequestAbortedException {
  /// Create new request cancelled exception.
  RequestCanceledException(this.reason, Uri uri) : super(
    'Request canceled${(reason?.isEmpty ?? true) ? '' : ': $reason'}',
    uri,
  );

  /// Reason caused the request to be canceled.
  final String? reason;
}
