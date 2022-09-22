import 'dart:js';
import 'package:on_hand/chrome_bridge/chrome_port.dart';
import 'package:on_hand/chrome_bridge/chrome_runtime_connect_info.dart';
import 'package:on_hand/chrome_bridge/common/chrome_common.dart';

abstract class ChromeRuntime {
  static ChromePort? connect({
    required ChromeRuntimeConnectInfo connectInfo,
    String? extensionId,
  }) {
    var args = JsArray();
    if (extensionId != null) args.add(extensionId);
    args.add(ChromeCommon.jsify(connectInfo));
    return ChromePort.fromProxy(
        ChromeCommon.runtime.callMethod('connect', args));
  }
}
