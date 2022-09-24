import 'dart:async';
import 'dart:convert';
import 'dart:js';
import 'package:flutter/foundation.dart';
import 'package:on_hand/chrome_bridge/chrome_communication_message.dart';
import 'package:on_hand/chrome_bridge/chrome_message_event.dart';
import 'package:on_hand/chrome_bridge/chrome_port.dart';
import 'package:on_hand/chrome_bridge/chrome_runtime.dart';
import 'package:on_hand/chrome_bridge/chrome_runtime_connect_info.dart';
import 'package:on_hand/chrome_bridge/common/chrome_common.dart';
import 'package:on_hand/global/global_data.dart';
import 'package:on_hand/helpers/utils.dart';

typedef MessageHandler = Future<dynamic> Function(dynamic data, String? error);

abstract class GlobalChrome {
  static final Map<String, Completer<dynamic>> _awaitingMessages =
      <String, Completer<dynamic>>{};
  static final Map<String, MessageHandler> _messageHandlers = {
    'get-data': GlobalChrome.handleGetData
  };
  static ChromePort? _port;
  static StreamSubscription<ChromeMessageEvent>? _streamSubscription;

  static bool get supported => ChromeCommon.isWebExtension;
  static bool get connected => _port != null;

  static String _getUniquePortName() => 'content-${Utils.generateUUID()}';

  static void connect() {
    if (!supported) return;
    disconnect();
    _port = ChromeRuntime.connect(
      connectInfo: ChromeRuntimeConnectInfo(name: _getUniquePortName()),
    );
    _streamSubscription = _port!.onMessage.listen((event) {
      final message = ChromeCommunicationMessage.fromProxy(event.message);
      final completer = _awaitingMessages[message.uuid];
      if (completer != null) {
        if (message.error != null) {
          completer.completeError(message.error!);
        } else {
          completer.complete(message.data);
        }
        _awaitingMessages.remove(message.uuid);
      } else {
        debugPrint(
            'MESSAGE IN CONTENT SCRIPT: type=\'${message.type}\', data=\'${message.data}\', error=\'${message.error}\'');
        final handler = _messageHandlers[message.type];
        if (handler != null) {
          handler(message.data, message.error).then((responseData) {
            final msg = ChromeCommunicationMessage(
              uuid: message.uuid,
              type: message.type,
              data: ChromeCommon.jsify(responseData),
            ).toJs();
            _port!.postMessage(msg);
          }).onError((error, stackTrace) {
            final strError = error is String ? error : jsonEncode(error);
            final msg = ChromeCommunicationMessage(
              uuid: message.uuid,
              type: message.type,
              error: strError,
            ).toJs();
            _port!.postMessage(msg);
          });
        } else {
          final msg = ChromeCommunicationMessage(
            uuid: message.uuid,
            type: message.type,
            error: 'There is no handler for this message',
          ).toJs();
          _port!.postMessage(msg);
        }
      }
    });
  }

  static void disconnect() {
    if (!supported) return;
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
    if (!supported) {
      return completer.completeError(
        'Unable to send message because the app is not a chrome extension.',
      );
    }
    if (_port == null) {
      return completer.completeError(
        'There is no connection to the ServiceWorker.',
      );
    }
    if (!completer.isCompleted) {
      final uuid = Utils.generateUUID();
      _awaitingMessages[uuid] = completer;
      _port!.postMessage(ChromeCommunicationMessage(
        uuid: uuid,
        type: type,
        data: data,
        error: error,
      ));
    }
    return completer.future;
  }

  static Future<dynamic> handleGetData(dynamic data, String? error) async {
    final groupList = GlobalData.appData.groups.map((g) => g.title).toList();
    return groupList;
  }
}
