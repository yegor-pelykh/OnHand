import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfo {
  static final _deviceInfoPlugin = DeviceInfoPlugin();

  static Future<BrowserName> getBrowserName() async {
    final browserInfo = await _deviceInfoPlugin.webBrowserInfo;
    return browserInfo.browserName;
  }
}
