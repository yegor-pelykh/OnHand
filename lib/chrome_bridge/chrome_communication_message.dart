import 'package:on_hand/chrome_bridge/common/chrome_common.dart';
import 'package:on_hand/chrome_bridge/common/chrome_object.dart';

class ChromeCommunicationMessage extends ChromeObject {
  ChromeCommunicationMessage({
    required String uuid,
    required String type,
    String? data,
    String? error,
  }) {
    this.uuid = uuid;
    this.type = type;
    this.data = data;
    this.error = error;
  }

  ChromeCommunicationMessage.fromProxy(super.jsProxy) : super.fromProxy();

  /// Message unique ID.
  String get uuid => jsProxy['uuid'];
  set uuid(String value) => jsProxy['uuid'] = value;

  /// Message type.
  String get type => jsProxy['type'];
  set type(String value) => jsProxy['type'] = value;

  /// The data sent with this message.
  String? get data => jsProxy['data'];
  set data(String? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'data', value);

  /// The error message.
  String? get error => jsProxy['error'];
  set error(String? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'error', value);
}
