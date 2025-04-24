import 'package:fetch_api/fetch_api.dart' /* show RequestRedirect, Response */ if (dart.library.io) '';

import 'fetch_client.dart' if (dart.library.io) 'fetch_client_io_shim.dart';
import 'fetch_response.dart';


/// Policy that determines how [FetchClient] should handle redirects.
enum RedirectPolicy {
  /// Default policy - always follow redirects.
  /// If redirect is occurred, the only way to know about it is via
  /// [FetchResponse.redirected] and [FetchResponse.url].
  alwaysFollow,
  /// Probe via HTTP `GET` request.
  /// 
  /// In this mode request is made with [RequestRedirect.manual], with
  /// no redirects, normal response is returned as usual.
  /// 
  /// If redirect is occurred, additional `GET` request will be sent and
  /// canceled before body will be available. Returning response with only
  /// headers and artificial `Location` header crafted from [Response.url].
  /// 
  /// Note that such response will always be crafted as `302 Found` and there's
  /// no way to get intermediate redirects, so you will get the targeted
  /// redirect as if the original server returned it.
  probe,
  /// Same as [probe] but using `HEAD` method and therefore no cancel is needed.
  probeHead;
}
