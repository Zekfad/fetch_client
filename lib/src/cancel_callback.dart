import 'request_canceled_exception.dart';


/// Type of cancel method, [reason] is passed to [RequestCanceledException.reason].
typedef CancelCallback = void Function([ String? reason, ]);
