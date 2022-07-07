import 'dart:html';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:on_hand/helpers/device_info.dart';

class UrlLauncher {
  static Future<void> launch(Uri uri, bool newTab) async {
    final a = AnchorElement(href: uri.toString());
    if (newTab) {
      a.target = '_blank';
      final browserName = await DeviceInfo.getBrowserName();
      final evt =
          MouseEvent('click', ctrlKey: browserName == BrowserName.firefox);
      a.dispatchEvent(evt);
    } else {
      a.target = '_self';
      final evt = MouseEvent('click');
      a.dispatchEvent(evt);
    }
  }
}
