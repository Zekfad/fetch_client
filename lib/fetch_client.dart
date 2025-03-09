/// Fetch based HTTP client.
/// Exports necessary fetch request options and client with response.
// ignore: unnecessary_library_name
library fetch_client;


export 'package:fetch_api/enums.dart' show RequestCache, RequestCredentials, RequestMode, RequestReferrerPolicy;

export 'src/fetch_client.dart' if (dart.library.io) 'src/fetch_client_io_shim.dart';
export 'src/fetch_request.dart';
export 'src/fetch_response.dart';
export 'src/redirect_policy.dart';
export 'src/request_canceled_exception.dart';
