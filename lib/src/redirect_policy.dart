import 'package:fetch_api/fetch_api.dart' show RequestRedirect, ResponseInstanceMembers;

import 'fetch_client.dart';
import 'fetch_response.dart';


/// How [FetchClient] should handle redirects.
enum RedirectPolicy {
  /// Default policy - always follow redirects.
  /// If redirect is occurred the only way to know about it is via
  /// [FetchResponse.redirected] and [FetchResponse.url].
  alwaysFollow,
  /// Probe via HTTP `GET` request.
  /// 
  /// Is this mode request is made with [RequestRedirect.manual], with
  /// no redirects, normal response is returned as usual.
  /// 
  /// If redirect is occurred additional `GET` request will be send and canceled
  /// before body will be available. Returning response with only headers and
  /// artificial `Location` header crafted from [ResponseInstanceMembers.url].
  /// 
  /// Note that such response will always be crafted as `302 Found` and there's
  /// no way to get intermediate redirects, so you will get target redirect as
  /// if the original server returned it.
  probe,
  /// Same as [probe] but using `HEAD` method and therefore no cancel is needed.
  probeHead;
}
