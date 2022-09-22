import 'dart:js';
import 'package:on_hand/chrome_bridge/common/chrome_common.dart';
import 'package:on_hand/chrome_bridge/common/chrome_object.dart';

class ChromeRuntimeConnectInfo extends ChromeObject {
  ChromeRuntimeConnectInfo({
    bool? includeTlsChannelId,
    String? name,
  }) {
    if (includeTlsChannelId != null) {
      this.includeTlsChannelId = includeTlsChannelId;
    }
    if (name != null) {
      this.name = name;
    }
  }

  ChromeRuntimeConnectInfo.fromProxy(JsObject jsProxy)
      : super.fromProxy(jsProxy);

  /// Whether the TLS channel ID will be passed into onConnectExternal for
  /// processes that are listening for the connection event.
  bool? get includeTlsChannelId => jsProxy['includeTlsChannelId'];
  set includeTlsChannelId(bool? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'includeTlsChannelId', value);

  /// Will be passed into onConnect for processes that are listening for the
  /// connection event.
  String? get name => jsProxy['name'];
  set name(String? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'name', value);
}
