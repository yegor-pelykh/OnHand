import 'dart:async';
import 'dart:js';

class ChromeStreamController<T extends Object> {
  final Function _apiProvider;
  final String _eventName;
  late final StreamController<T> _controller;
  late final Function _listener;
  bool _handlerAdded = false;

  JsObject get _api => _apiProvider();

  ChromeStreamController.noArgs(
    this._apiProvider,
    this._eventName,
  ) {
    _controller = StreamController<T>.broadcast(
      onListen: _ensureHandlerAdded,
      onCancel: _removeHandler,
    );
    _listener = () {
      _controller.add({} as T);
    };
  }

  ChromeStreamController.oneArg(
    this._apiProvider,
    this._eventName,
    Function transformer, [
    returnVal,
  ]) {
    _controller = StreamController<T>.broadcast(
      onListen: _ensureHandlerAdded,
      onCancel: _removeHandler,
    );
    _listener = ([arg1]) {
      _controller.add(transformer(arg1));
      return returnVal;
    };
  }

  ChromeStreamController.twoArgs(
    this._apiProvider,
    this._eventName,
    Function transformer, [
    returnVal,
  ]) {
    _controller = StreamController<T>.broadcast(
      onListen: _ensureHandlerAdded,
      onCancel: _removeHandler,
    );
    _listener = ([arg1, arg2]) {
      _controller.add(transformer(arg1, arg2));
      return returnVal;
    };
  }

  ChromeStreamController.threeArgs(
    this._apiProvider,
    this._eventName,
    Function transformer, [
    returnVal,
  ]) {
    _controller = StreamController<T>.broadcast(
      onListen: _ensureHandlerAdded,
      onCancel: _removeHandler,
    );
    _listener = ([arg1, arg2, arg3]) {
      _controller.add(transformer(arg1, arg2, arg3));
      return returnVal;
    };
  }

  bool get hasListener {
    return _controller.hasListener;
  }

  Stream<T> get stream {
    return _controller.stream;
  }

  void _ensureHandlerAdded() {
    if (!_handlerAdded) {
      final jsEvent = _api[_eventName];
      JsObject event =
          (jsEvent is JsObject ? jsEvent : JsObject.fromBrowserObject(jsEvent));
      event.callMethod('addListener', [_listener]);
      _handlerAdded = true;
    }
  }

  void _removeHandler() {
    if (_handlerAdded) {
      final jsEvent = _api[_eventName];
      JsObject event =
          (jsEvent is JsObject ? jsEvent : JsObject.fromBrowserObject(jsEvent));
      event.callMethod('removeListener', [_listener]);
      _handlerAdded = false;
    }
  }
}
