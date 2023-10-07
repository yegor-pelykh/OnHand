import 'dart:async';
import 'dart:convert';
import 'package:on_hand/chrome_bridge/chrome_communication_message.dart';
import 'package:on_hand/chrome_bridge/chrome_message_event.dart';
import 'package:on_hand/chrome_bridge/chrome_port.dart';
import 'package:on_hand/chrome_bridge/chrome_runtime.dart';
import 'package:on_hand/chrome_bridge/chrome_runtime_connect_info.dart';
import 'package:on_hand/global/global_data.dart';
import 'package:on_hand/helpers/utils.dart';

typedef MessageHandler = Future<dynamic> Function(dynamic data, dynamic error);

abstract class GlobalChrome {
  static final Map<String, Completer<dynamic>> _awaitingMessages = <String, Completer<dynamic>>{};
  static final Map<String, MessageHandler> _messageHandlers = {
    'get-data': GlobalChrome.handleGetData
  };
  static ChromePort? _port;
  static StreamSubscription<ChromeMessageEvent>? _streamSubscription;

  static bool get connected => _port != null;

  static String _getUniquePortName() => 'content-${Utils.generateUUID()}';

  static void connect() {
    disconnect();
    _port = ChromeRuntime.connect(
      connectInfo: ChromeRuntimeConnectInfo(name: _getUniquePortName()),
    );
    _streamSubscription = _port!.onMessage.listen((event) {
      final message = ChromeCommunicationMessage.fromProxy(event.message);
      final dataObj = message.data != null ? jsonDecode(message.data!) : null;
      final errorObj = message.error != null ? jsonDecode(message.error!) : null;
      final completer = _awaitingMessages[message.uuid];
      if (completer != null) {
        if (errorObj != null) {
          completer.completeError(errorObj);
        } else {
          completer.complete(dataObj);
        }
        _awaitingMessages.remove(message.uuid);
      } else {
        final response = ChromeCommunicationMessage(
          uuid: message.uuid,
          type: message.type,
        );
        final handler = _messageHandlers[message.type];
        if (handler != null) {
          handler(dataObj, errorObj).then((responseData) {
            if (responseData != null) {
              response.data = jsonEncode(responseData);
            }
            _port!.postMessage(response.toJs());
          }).onError((error, stackTrace) {
            if (error != null) {
              response.error = jsonEncode(error);
            }
            _port!.postMessage(response.toJs());
          });
        } else {
          response.error = jsonEncode('There is no handler for this message');
          _port!.postMessage(response.toJs());
        }
      }
    });
  }

  static void disconnect() {
    if (_streamSubscription != null) {
      _streamSubscription!.cancel();
      _streamSubscription = null;
    }
    if (_port != null) {
      _port!.disconnect();
      _port = null;
    }
  }

  static Future<dynamic> sendMessage({
    required String type,
    dynamic data,
    String? error,
  }) async {
    final completer = Completer<dynamic>();
    if (_port == null) {
      return completer.completeError(
        'There is no connection to the ServiceWorker.',
      );
    }
    if (!completer.isCompleted) {
      final uuid = Utils.generateUUID();
      _awaitingMessages[uuid] = completer;
      final msg = ChromeCommunicationMessage(
        uuid: uuid,
        type: type,
      );
      if (data != null) {
        msg.data = jsonEncode(data);
      }
      if (error != null) {
        msg.error = jsonEncode(error);
      }
      _port!.postMessage(msg);
    }
    return completer.future;
  }

  static Future<dynamic> handleGetData(dynamic data, dynamic error) async {
    return GlobalData.groupStorage.titles;
  }
}
