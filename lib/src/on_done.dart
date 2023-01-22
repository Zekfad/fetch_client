import 'dart:async';


/// Calls [onDone] once [stream] (a single-subscription [Stream]) is finished.
///
/// The return value, also a single-subscription [Stream] should be used in
/// place of [stream] after calling this method.
Stream<T> onDone<T>(Stream<T> stream, void Function() onDone) =>
  stream.transform(
    StreamTransformer.fromHandlers(
      handleDone: (sink) {
        sink.close();
        onDone();
      },
    ),
  );
