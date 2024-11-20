import 'package:on_hand/chrome_bridge/chrome_message_event.dart';
import 'package:on_hand/chrome_bridge/chrome_message_sender.dart';
import 'package:on_hand/chrome_bridge/common/chrome_common.dart';
import 'package:on_hand/chrome_bridge/common/chrome_object.dart';
import 'package:on_hand/chrome_bridge/common/chrome_stream_controller.dart';

/// An object which allows two way communication with other pages. See <a
/// href="messaging#connect">Long-lived connections</a> for more information.
class ChromePort extends ChromeObject {
  ChromePort({
    String? name,
    ChromeMessageSender? sender,
  }) {
    if (name != null) this.name = name;
    if (sender != null) this.sender = sender;
  }

  ChromePort.fromProxy(super.jsProxy) : super.fromProxy();

  /// The name of the port, as specified in the call to [runtime.connect].
  String get name => jsProxy['name'];
  set name(String value) => jsProxy['name'] = value;

  /// This property will <b>only</b> be present on ports passed to
  /// $(ref:runtime.onConnect onConnect) / $(ref:runtime.onConnectExternal
  /// onConnectExternal) listeners.
  ChromeMessageSender? get sender =>
      ChromeMessageSender.fromProxyN(jsProxy['sender']);
  set sender(ChromeMessageSender? value) => ChromeCommon.setNullableProperty(
      jsProxy, 'sender', ChromeCommon.jsify(value));

  ChromeStreamController? _onDisconnect;
  Stream get onDisconnect {
    _onDisconnect ??= ChromeStreamController.noArgs(
      () => jsProxy,
      'onDisconnect',
    );
    return _onDisconnect!.stream;
  }

  ChromeStreamController<ChromeMessageEvent>? _onMessage;
  Stream<ChromeMessageEvent> get onMessage {
    _onMessage ??= ChromeStreamController<ChromeMessageEvent>.threeArgs(
      () => jsProxy,
      'onMessage',
      ChromeMessageEvent.from,
    );
    return _onMessage!.stream;
  }

  void postMessage([var arg1]) =>
      jsProxy.callMethod('postMessage', [ChromeCommon.jsify(arg1)]);

  void disconnect() => jsProxy.callMethod('disconnect');
}
