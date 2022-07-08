import 'dart:ui';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';

class DeviceInfo {
  static final _deviceInfoPlugin = DeviceInfoPlugin();

  static Future<BrowserName> getBrowserName() async {
    final browserInfo = await _deviceInfoPlugin.webBrowserInfo;
    return browserInfo.browserName;
  }

  static Future<Locale> getBrowserLocale() async {
    final browserInfo = await _deviceInfoPlugin.webBrowserInfo;
    return browserInfo.language?.toLocale() ??
        const Locale.fromSubtags(languageCode: 'en');
  }
}
