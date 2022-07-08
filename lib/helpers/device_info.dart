import 'dart:ui';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfo {
  static final _deviceInfoPlugin = DeviceInfoPlugin();

  static Future<BrowserName> getBrowserName() async {
    final browserInfo = await _deviceInfoPlugin.webBrowserInfo;
    return browserInfo.browserName;
  }

  static Future<Locale> getBrowserLocale() async {
    final browserInfo = await _deviceInfoPlugin.webBrowserInfo;
    if (browserInfo.language == null) {
      return const Locale.fromSubtags(languageCode: 'en');
    }
    final parts = browserInfo.language!.split('-');
    return Locale.fromSubtags(languageCode: parts.isNotEmpty ? parts[0] : 'en');
  }
}
