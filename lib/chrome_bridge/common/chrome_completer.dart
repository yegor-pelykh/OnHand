import 'dart:async';
import 'package:on_hand/chrome_bridge/common/chrome_common.dart';

/// An object for handling completion callbacks
class ChromeCompleter<T> {
  final Completer<T> _completer = Completer();
  late final Function _callback;

  ChromeCompleter.noArgs() {
    _callback = ([_]) {
      final error = ChromeCommon.lastError;
      if (error != null) {
        _completer.completeError(error);
      } else {
        _completer.complete();
      }
    };
  }

  ChromeCompleter.oneArg([Function? transformer]) {
    _callback = ([arg1]) {
      final error = ChromeCommon.lastError;
      if (error != null) {
        _completer.completeError(error);
      } else {
        if (transformer != null) {
          arg1 = transformer(arg1);
        }
        _completer.complete(arg1);
      }
    };
  }

  ChromeCompleter.twoArgs(Function transformer) {
    _callback = ([arg1, arg2]) {
      final error = ChromeCommon.lastError;
      if (error != null) {
        _completer.completeError(error);
      } else {
        _completer.complete(transformer(arg1, arg2));
      }
    };
  }

  Future<T> get future => _completer.future;
  Function get callback => _callback;
}
