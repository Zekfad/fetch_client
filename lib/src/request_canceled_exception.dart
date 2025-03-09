import 'package:http/http.dart';


/// An exception caused by canceling request.
class RequestCanceledException extends ClientException {
  /// Create new request cancelled exception.
  RequestCanceledException(this.reason, Uri uri) : super(
    'request canceled${reason.isEmpty ? '' : ': $reason'}',
    uri,
  );

  /// Reason caused request to be canceled.
  final String reason;
}
